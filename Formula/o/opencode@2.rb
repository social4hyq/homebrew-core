class OpencodeAT2 < Formula
  desc "OpenCode v2 preview — AI coding agent CLI, HarmonyOS aarch64, built from source"
  homepage "https://github.com/anomalyco/opencode"
  # v2 is a live development branch (no release tags yet). URL pins the v2
  # branch HEAD via git revision (bun.rb pattern); version stays a
  # human-readable beta tag so bump-formula-pr's version comparison doesn't
  # fight the commit SHA. livecheck watches the v2 branch HEAD via GitHub API;
  # autobump.yml opens a PR when a new commit lands.
  url "https://github.com/anomalyco/opencode.git", revision: "84fd347afaed9617b7b29744086657fa029bbe68", branch: "v2"
  version "2.0.0-beta"
  license "MIT"
  revision 12

  livecheck do
    url "https://api.github.com/repos/anomalyco/opencode/commits?sha=v2&per_page=1"
    strategy :json do |json|
      json.first&.dig("sha")
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode@2-v2.0.0-beta-r11"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "44af16ba08bffea80ea47fa226e64680636d5caf12f5fd91ac6bffb650034b13"
  end

  # opencode2 is a `bun build --compile` single binary: OHOS bun runtime + JS
  # bundle + native .so all embedded. Since bun r31 the ohos-compat-shim is
  # statically linked into every compile output, so there is NO runtime shim
  # dependency and no LD_PRELOAD wrapper.
  #
  # v2 monorepo restructure vs v1: the CLI package moved from packages/opencode
  # to packages/cli (binary renamed opencode -> opencode2). The build script is
  # at packages/cli/script/build.ts (rewritten, no web-UI embedding step). The
  # web.ts command was removed entirely (no patch needed). Native deps are
  # fewer: only @opentui/core (0.4.5) and bun-pty (0.4.10) need @ohos-ports/*
  # overrides; lightningcss/tailwindcss-oxide are gone from the CLI tree.
  #
  # `bun install --ignore-scripts` is intentional: lifecycle scripts are
  # irrelevant to signing, and trustedDependencies would fall back to source
  # builds on openharmony for native bindings the app never loads.
  #
  # @parcel/watcher: replaced linux-arm64-musl optional dep with @ohos-ports
  # pre-signed binary + getBackend() openharmony → inotify patch. File
  # watching is now functional on OHOS (inotify backend, no watchman).
  depends_on "bun" => :build
  depends_on "ohos-sdk" => :build # llvm-readelf (verify .codesign section)

  # All OHOS source adaptations are done via inreplace in install() — zero
  # .patch files. The "reuse musl slot" strategy (hijack the existing
  # linux-arm64-musl target entry instead of adding a new one) eliminates the
  # structural array-insertion hunk, leaving only single-line string
  # replacements. Version bumps only need url + sha256 + bottle root_url.
  # See social4hyq/ohos-opencode2 dev for the canonical diff these mirror
  # (fork-diff invariant; 4 patches → inreplace 2026-07-31).

  def install
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    (buildpath/".bun-tmp").mkpath
    ENV["BUN_INSTALL_CACHE_DIR"] = (HOMEBREW_CACHE/"bun-install-cache").to_s

    # Workspace packages not needed for the CLI build (drops electron, web
    # apps, storybook, etc. from the install set entirely). Only delete
    # packages matched by the "packages/*" glob — v2's root package.json also
    # lists explicit workspace entries ("packages/slack") and sub-globs
    # ("packages/console/*", "packages/stats/*") that bun install will hard-
    # error on if the directory is missing, so those stay.
    # session-ui is deleted alongside app: it references app's vendored SDK
    # tarball via file:../app/vendor/ (both have a file: dependency on a
    # .tgz inside packages/app/vendor/). The CLI dep chain doesn't touch
    # either.
    # enterprise is deleted alongside session-ui: it depends on
    # @opencode-ai/session-ui (workspace:*), so leaving it in place makes
    # bun install fail to resolve session-ui after its directory is gone.
    rm_r %w[packages/desktop packages/app packages/session-ui packages/web
            packages/www packages/storybook packages/enterprise]

    # Native dep overrides (replaces ohos-ports-deps.patch). v2 only needs
    # @ohos-ports/opentui-core + @ohos-ports/bun-pty (no lightningcss/
    # tailwindcss-oxide in the CLI tree).
    # bun-pty/@parcel/watcher have no upstream override entry, so they are
    # added right after the @opentui/core override this same replacement
    # writes — no assumption about upstream's overrides key ordering. The nil
    # check makes a vanished anchor fail loudly.
    inreplace "package.json" do |s|
      overrides = [
        '"@opentui/core": "npm:@ohos-ports/opentui-core@0.4.5-patch.1",',
        '    "bun-pty": "npm:@ohos-ports/bun-pty@0.4.10",',
        '    "@parcel/watcher-linux-arm64-musl": "npm:@ohos-ports/parcel-watcher-openharmony-arm64@2.5.1",',
      ]
      s.gsub!('"@opentui/core": "catalog:",', overrides.join("\n")) ||
        odie("opencode@2: @opentui/core override anchor not found in package.json")
    end

    # Home dir fallback for global projects (replaces project-global-
    # worktree.patch). v2 only touches packages/core/src/project.ts
    # (no packages/opencode variant).
    inreplace "packages/core/src/project.ts" do |s|
      s.sub!('import path from "path"', "import os from \"os\"\nimport path from \"path\"") ||
        odie("opencode@2: project.ts import anchor not found")
      s.sub!("path.parse(input).root", "os.homedir()") ||
        odie("opencode@2: project.ts path.parse anchor not found")
    end

    # File watcher: add openharmony → inotify backend mapping so getBackend()
    # returns "inotify" instead of undefined on OHOS (enables native file watching).
    inreplace "packages/core/src/filesystem/watcher.ts",
      'if (process.platform === "linux") return "inotify"',
      'if (process.platform === "linux" || process.platform === "openharmony") return "inotify"'

    # Flip openharmony-arm64 os markers in bun.lock (replaces
    # bun-lock-openharmony-os.patch). Same regex as opencode.
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

    # Disable upstream's npm anti-typosquatting minimum-release-age policy: it
    # blocks freshly-published @ohos-ports/* packages (< 3 days old). Removing
    # the key restores bun's default (null = disabled). inreplace raises if
    # upstream rewords or drops the line, so a bump can't silently re-enable
    # the policy. (bun has no "minimumReleaseAgeMs" key — an unknown bunfig
    # key is silently ignored, verified on bun 1.4.0.)
    inreplace "bunfig.toml", "minimumReleaseAge = 259200\n", ""
    system "bun", "install", "--ignore-scripts"

    # Script.version short-circuits on OPENCODE_VERSION (no git / registry
    # lookup), which also flips Script.channel to "latest".
    ENV["OPENCODE_VERSION"] = version.to_s

    # build.ts adaptations (replaces build-ohos-target.patch). Reuse the
    # existing linux-arm64-musl target slot instead of adding a new one:
    #   1. os check: allow linux-arm64-musl through on OHOS
    #   2. abi check: keep musl target on OHOS in single-flag mode
    #   3. compile target: use bun-linux-arm64-ohos for musl on OHOS
    inreplace "packages/cli/script/build.ts",
      "if (item.os !== process.platform || item.arch !== process.arch) return false",
      "if ((item.os !== process.platform || item.arch !== process.arch) && " \
      "!(process.platform === \"openharmony\" && " \
      "item.os === \"linux\" && item.arch === \"arm64\" && " \
      "item.abi === \"musl\")) return false"
    # The abi guard is anchored on the preceding avx2 line: the bare
    # "return item.abi === undefined" string is short enough to collide with
    # unrelated future code in this file (gsub! would rewrite every match).
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

    cd "packages/cli" do
      system "bun", "run", "script/build.ts", "--single"
    end

    out = "packages/cli/dist/cli-linux-arm64-musl/bin/opencode2"
    odie "opencode2 binary missing" unless File.exist?(out)

    # The device kernel refuses to exec unsigned ELFs; bun's compile step must
    # have produced a .codesign section (ohos_sign, bun.rb r16+).
    readelf = formula_opt_prefix("ohos-sdk")/"native/llvm/bin/llvm-readelf"
    sections = Utils.safe_popen_read(readelf.to_s, "--section-headers", out)
    odie "compiled binary lacks .codesign section" unless sections.include?(".codesign")

    # The launcher wrapper defaults TMPDIR to a writable EL2 path (OHOS /tmp
    # is read-only in app contexts); override via OPENCODE_TMPDIR. Self-reference
    # via opt_libexec (not libexec) so the baked path stays stable across the
    # HOMEBREW_CELLAR flat/nested flip.
    #
    # The wrapper also isolates XDG_DATA_HOME: v2 and opencode (v1)
    # would otherwise share ~/.local/share/opencode/opencode.db, and v2's
    # migrations (e.g. event.created NOT NULL) break v1's session creation
    # ("creating a session failed"). v2 gets its own data root; an
    # explicitly-set XDG_DATA_HOME is still honored.
    mkdir_p libexec/"bin"
    libexec.install out => "bin/opencode2"
    (bin/"opencode2").write <<~SH
      #!/bin/sh
      export TMPDIR="${OPENCODE_TMPDIR:-/data/storage/el2/base/cache}"
      export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share-v2}"
      exec "#{opt_libexec}/bin/opencode2" "$@"
    SH
    chmod 0755, bin/"opencode2"

    # Shell completions come from the binary itself (effect CLI built-in
    # `--completions bash|zsh|fish`) — always in sync, no handwritten list
    # to drift when autobump advances the revision pin. Generate from the
    # libexec binary: the bin/opencode2 wrapper execs opt_libexec, whose
    # opt/ symlink only exists after install.
    # base_name must be the command name, not the formula name: without it
    # the helper defaults to `name` (opencode@2 — the executable is under
    # libexec, not bin, so the basename fallback doesn't apply), and bash/fish
    # completions would be installed under a filename that never matches the
    # `opencode2` command.
    generate_completions_from_executable(libexec/"bin/opencode2", "--completions",
                                         base_name: "opencode2")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode2 --version 2>&1")
  end
end
