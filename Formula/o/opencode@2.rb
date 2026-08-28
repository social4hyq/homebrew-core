class OpencodeAT2 < Formula
  desc "OpenCode v2 preview — AI coding agent CLI, HarmonyOS aarch64, built from source"
  homepage "https://github.com/anomalyco/opencode"
  # v2 is a live branch (no tags yet). Version scheme = npm: `version` mirrors
  # the @opencode-ai/cli beta dist-tag (0.0.0-beta-<build>), and the git pin
  # below is the v2 tip at that npm release's publish timestamp (upstream CI
  # publishes the branch tip per merge; no gitHead in npm metadata, so the
  # mapping is time-based — see autobump.sh's custom bump path). The tip that
  # published beta-17898 (2026-08-22 07:02Z) committed at 06:53Z.
  # Do NOT add `branch:` back: Homebrew's extract_ref prefers :branch over
  # :revision, so `branch: "v2", revision: <sha>` silently builds the moving
  # branch tip instead of the pin. That tip dropped generate.ts (models
  # snapshot is committed upstream as
  # packages/core/src/models-dev/snapshot.txt — no build-time fetch) and
  # restructured build.ts (app-assets; pass --skip-web-ui to skip the
  # packages/app web build, which rm_r deletes). opentui is 0.5.8 now:
  # @ohos-npm-ports/opentui-core fixes libopentui.so's pthread_tryjoin_np
  # dependency at the source level (weak symbol), no LD_PRELOAD shim needed.
  # See social4hyq/ohos-opencode2 dev for canonical diff.
  url "https://github.com/anomalyco/opencode.git", revision: "ab6a01d1358ceefaca6073ee03084bffe1826595"
  version "0.0.0-beta-18314"
  license "MIT"
  # Baked-in channel was empty (see OPENCODE_CHANNEL below) — TUI crashed on
  # startup ("Invalid storage segment" segment-validates the channel), so the
  # fix changes the installed binary.
  # Version scheme changed 2.0.0-beta_N → npm's 0.0.0-beta-<build>, which
  # sorts BELOW the old string; version_scheme forces brew upgrade to treat
  # any scheme-1 version as newer than every scheme-0 (2.0.0-beta_24) keg.
  version_scheme 1

  # Livecheck the npm beta dist-tag (published v2 builds). The formula's
  # `version` uses the same scheme, so livecheck output is directly
  # comparable; autobump.sh's custom path maps a new npm version to the git
  # pin via the npm publish timestamp. npmmirror, not registry.npmjs.org:
  # Cloudflare intermittently serves CI runners a 200 non-JSON challenge
  # that kills livecheck with a bare exit 1 (observed 2026-08-23); the
  # mirror's dist-tag metadata is identical and CF-free.
  livecheck do
    url "https://registry.npmmirror.com/@opencode-ai/cli/beta"
    strategy :json do |json|
      json["version"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode@2-v0.0.0-beta-18230-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6dee538d0778e5399defd715712e5b6662c36120d41d2ae89fc392f4c1455fd0"
  end

  # `bun build --compile` single binary: runtime + JS + .so embedded; since
  # bun r31 ohos-compat-shim is statically linked (no runtime shim dep).
  # v2 monorepo restructure: CLI moved packages/opencode → packages/cli
  # (binary renamed opencode2). Build script: packages/cli/script/build.ts.
  # Native deps: opentui-core (@ohos-npm-ports 0.5.8-1) + @parcel/watcher
  # (@ohos-ports binary). `bun install --ignore-scripts`
  # (lifecycle scripts irrelevant to signing).
  depends_on "bun" => :build
  depends_on "ohos-sdk" => :build # llvm-readelf (verify .codesign section)

  # All OHOS adaptations via inreplace — zero .patch files.
  # See opencode.rb for the same pattern.

  def install
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    (buildpath/".bun-tmp").mkpath
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s

    # Drop workspace packages not needed for CLI build. Only delete packages/*
    # glob entries, not explicit workspace entries or sub-globs (bun install
    # errors on missing dirs).
    # session-ui + enterprise deleted together (cross-dependencies).
    rm_r %w[packages/desktop packages/app packages/session-ui packages/web
            packages/www packages/storybook packages/enterprise]

    # opentui-core (@ohos-npm-ports 0.5.8-1, dlopen loader patch + bundled
    # libopentui.so, source-level pthread_tryjoin_np fix) + parcel-watcher
    # (@ohos-ports). bun-pty is gone — the tip uses @lydell/node-pty, which
    # the CLI graph never imports (no rebuild needed; verified against the
    # pinned source).
    # The nil check makes a vanished anchor fail loudly.
    inreplace "package.json" do |s|
      overrides = [
        '"@opentui/core": "npm:@ohos-npm-ports/opentui-core@0.5.8-1",',
        '    "@parcel/watcher-linux-arm64-musl": "npm:@ohos-ports/parcel-watcher-openharmony-arm64@2.5.1",',
      ]
      s.gsub!('"@opentui/core": "catalog:",', overrides.join("\n")) ||
        odie("opencode@2: @opentui/core override anchor not found in package.json")
    end

    # Home dir fallback for global projects — dropped. Upstream's
    # effect/drizzle-orm rewrite removed the live path.parse(input).root
    # fallback from project.ts's resolve() itself (non-VCS directories now
    # resolve to their real path, never the filesystem root). The only
    # remaining path.parse(...).root is in the one-time v1→v2 DB migration,
    # gated behind an existing legacy `session` table — unreachable for this
    # formula, which has always tracked the v2 preview branch directly.

    # File watcher: add openharmony → inotify backend mapping so getBackend()
    # returns "inotify" instead of undefined on OHOS (enables native file watching).
    inreplace "packages/core/src/filesystem/watcher.ts",
      'if (process.platform === "linux") return "inotify"',
      'if (process.platform === "linux" || process.platform === "openharmony") return "inotify"'

    # Service discovery: default mismatch handling is "ignore" — any registered
    # background daemon is reused regardless of version, so a daemon left
    # running by a previous keg (its binary deleted on upgrade) keeps serving a
    # new CLI until it is restarted by hand. With per-revision version strings
    # (see OPENCODE_VERSION below) "replace" makes a client stop a mismatched
    # daemon and spawn one from its own build — stale daemons self-heal on the
    # next CLI use instead of answering 404s the client reports as
    # UnsupportedContentType (observed 2026-08-20, beta_15 daemon vs beta_22 CLI).
    inreplace "packages/cli/src/services/server-connection.ts",
      'const mismatch = args.mismatch ?? "ignore"',
      'const mismatch = args.mismatch ?? "replace"'

    # Flip openharmony-arm64 os markers. Same regex as opencode.rb.
    lockfile = (buildpath/"bun.lock").read
    injected = lockfile.gsub(
      /("[^"]*openharmony-arm64@[^"]+", "", \{ )"os": "none"(, "cpu": "arm64" \})/,
      %q(\1"os": "openharmony"\2),
    )
    if injected == lockfile
      opoo "opencode@2: no openharmony-arm64 os:none markers found in bun.lock " \
           "(upstream may have changed the lockfile format — verify the build)"
    else
      (buildpath/"bun.lock").atomic_write(injected)
    end

    # Disable npm minimum-release-age. See opencode.rb for rationale.
    inreplace "bunfig.toml", "minimumReleaseAge = 259200\n", ""
    system "bun", "install", "--ignore-scripts"

    # Script.version short-circuits on OPENCODE_VERSION (no git/registry lookup).
    # The revision suffix makes every rebuild's version string unique: service
    # discovery gates client/daemon compatibility on this string, and without it
    # rebuilds of the same npm build look identical to the gate (see the
    # mismatch flip above).
    ENV["OPENCODE_VERSION"] = "#{version}_#{revision}"

    # Script.channel falls through to `git branch --show-current` when
    # OPENCODE_VERSION starts with "0.0.0-" (always true here) and
    # OPENCODE_CHANNEL is unset — under brew's detached HEAD that yields "".
    # The empty channel is baked into the binary and breaks two things at
    # runtime: the TUI storage keys its state directory by channel and its
    # segment validation (`^[a-zA-Z0-9][a-zA-Z0-9._-]*$`) crashes the TUI at
    # startup ("Invalid storage segment"), and the updater pokes
    # update.opencode.ai/api//cli/npm (404 spam every 10 min). "beta" matches
    # the npm dist-tag this formula tracks; updater stays read-only either way
    # (brew installs fail its npm/pnpm/bun/yarn method detection).
    ENV["OPENCODE_CHANNEL"] = "beta"

    # build.ts adaptations (reuse linux-arm64-musl target slot):
    #   1. os check: allow linux-arm64-musl through on OHOS
    #   2. abi check: keep musl target on OHOS in single-flag mode
    #   3. compile target: use bun-linux-arm64-ohos for musl on OHOS
    inreplace "packages/cli/script/build.ts",
      "if (item.os !== process.platform || item.arch !== process.arch) return false",
      "if ((item.os !== process.platform || item.arch !== process.arch) && " \
      "!(process.platform === \"openharmony\" && " \
      "item.os === \"linux\" && item.arch === \"arm64\" && " \
      "item.abi === \"musl\")) return false"
    # Anchor on preceding avx2 line to avoid gsub! matching unrelated code.
    inreplace "packages/cli/script/build.ts",
      /(if \(item\.avx2 === false\) return baselineFlag\n\s*)return item\.abi === undefined/,
      '\1return process.platform === "openharmony" || item.abi === undefined'
    inreplace "packages/cli/script/build.ts" do |s|
      s.sub!("target: target.replace(binary, \"bun\") as Bun.Build.CompileTarget,",
             "target: (process.platform === \"openharmony\" && " \
             "item.abi === \"musl\" ? \"bun-linux-arm64-ohos\" : " \
             "target.replace(binary, \"bun\")) as Bun.Build.CompileTarget,") ||
        odie("opencode@2: build.ts compile-target anchor not found")
    end

    # compileExecutable() returns undefined when BUN_COMPILE_RELEASE is unset,
    # and Bun.build rejects that (executablePath must be a Bun executable).
    # Upstream pins a downloadable bun release; on OHOS there is none — use the
    # bun running the build script (the tap's OHOS build) as the template.
    inreplace "packages/cli/script/build.ts",
      "const release = process.env.BUN_COMPILE_RELEASE\n  if (!release) return",
      "const release = process.env.BUN_COMPILE_RELEASE\n  if (!release) return process.execPath"

    # Build-time models snapshot: none needed — upstream commits the models
    # data (packages/core/src/models-dev/snapshot.txt) since c254ba8a; no
    # fetch at build time.

    cd "packages/cli" do
      # --skip-web-ui: build.ts's buildAppArchive would otherwise run
      # `bun run build` in packages/app (deleted by rm_r above) to embed the
      # web UI archive; skipping leaves the archive empty and the TUI works.
      system "bun", "run", "script/build.ts", "--single", "--skip-web-ui"
    end

    out = "packages/cli/dist/cli-linux-arm64-musl/bin/opencode2"
    odie "opencode2 binary missing" unless File.exist?(out)

    # Verify .codesign section present. See opencode.rb.
    readelf = formula_opt_prefix("ohos-sdk")/"native/llvm/bin/llvm-readelf"
    sections = Utils.safe_popen_read(readelf.to_s, "--section-headers", out)
    odie "compiled binary lacks .codesign section" unless sections.include?(".codesign")

    # Isolates XDG_DATA_HOME ($HOME/.local/share-v2) so v2's DB migrations don't
    # break v1's session creation. opt_libexec keeps baked path stable across
    # flat/nested cellar flip.
    mkdir_p libexec/"bin"
    libexec.install out => "bin/opencode2"

    (bin/"opencode2").write <<~SH
      #!/bin/sh
      export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share-v2}"
      exec "#{opt_libexec}/bin/opencode2" "$@"
    SH
    chmod 0755, bin/"opencode2"

    # Completions from binary's --completions (always in sync).
    # base_name must be 'opencode2' not formula name (libexec binary).
    generate_completions_from_executable(libexec/"bin/opencode2", "--completions",
                                         base_name: "opencode2")
  end

  # No post_upgrade here: this Harmonybrew fork never invokes it (post_install
  # exists, post_upgrade has zero call sites), so such a hook would be dead
  # code claiming to restart the background daemon on upgrade. The daemon is
  # intentionally unmanaged — the version-gate flip above (mismatch "replace")
  # already makes the first CLI use after an upgrade replace a daemon left
  # running by a previous keg (verified on device 2026-08-20).

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode2 --version 2>&1")
  end
end
