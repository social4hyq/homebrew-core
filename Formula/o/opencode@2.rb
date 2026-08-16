class OpencodeAT2 < Formula
  desc "OpenCode v2 preview — AI coding agent CLI, HarmonyOS aarch64, built from source"
  homepage "https://github.com/anomalyco/opencode"
  # v2 is a live branch (no tags yet); pinned git revision + beta version tag.
  # Do NOT add `branch:` back: Homebrew's extract_ref prefers :branch over
  # :revision, so `branch: "v2", revision: <sha>` silently builds the moving
  # branch tip instead of the pin. The pinned tip (2026-08-15, 825193400773)
  # dropped generate.ts (models snapshot is committed upstream as
  # packages/core/src/models-dev/snapshot.txt — no build-time fetch) and
  # restructured build.ts (app-assets; pass --skip-web-ui to skip the
  # packages/app web build, which rm_r deletes). opentui is 0.5.3 now: its
  # libopentui.so imports pthread_tryjoin_np, which OHOS musl lacks — the
  # wrapper LD_PRELOADs a small shim providing it (see install).
  # See social4hyq/ohos-opencode2 dev for canonical diff.
  url "https://github.com/anomalyco/opencode.git", revision: "825193400773cceab9b92f6bc63247d6dde3d580"
  version "2.0.0-beta"
  license "MIT"
  revision 15

  livecheck do
    url "https://api.github.com/repos/anomalyco/opencode/commits?sha=v2&per_page=1"
    strategy :json do |json|
      json.first&.dig("sha")
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode@2-v2.0.0-beta-r16"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "883f0a165a6bc73e16f6f89d97f8056c38c6ffb65b918fe27f697f57a6953240"
  end

  # `bun build --compile` single binary: runtime + JS + .so embedded; since
  # bun r31 ohos-compat-shim is statically linked (no runtime shim dep).
  # v2 monorepo restructure: CLI moved packages/opencode → packages/cli
  # (binary renamed opencode2). Build script: packages/cli/script/build.ts.
  # Native deps: opentui-core (@ohos-ports 0.5.3, needs pthread_tryjoin shim)
  # + @parcel/watcher (@ohos-ports binary). `bun install --ignore-scripts`
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

    # @ohos-ports overrides: opentui-core (0.5.3, dlopen loader patch +
    # bundled libopentui.so) + parcel-watcher only. bun-pty is gone — the
    # tip uses @lydell/node-pty, which the CLI graph never imports (no
    # rebuild needed; verified against the pinned source).
    # The nil check makes a vanished anchor fail loudly.
    inreplace "package.json" do |s|
      overrides = [
        '"@opentui/core": "npm:@ohos-ports/opentui-core@0.5.3",',
        '    "@parcel/watcher-linux-arm64-musl": "npm:@ohos-ports/parcel-watcher-openharmony-arm64@2.5.1",',
      ]
      s.gsub!('"@opentui/core": "catalog:",', overrides.join("\n")) ||
        odie("opencode@2: @opentui/core override anchor not found in package.json")
    end

    # Home dir fallback for global projects. See opencode.rb.
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
    ENV["OPENCODE_VERSION"] = version.to_s

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

    # opentui 0.5.3's libopentui.so imports pthread_tryjoin_np, which OHOS musl
    # lacks (musl < 1.2.5; symbol confirmed absent from the device libc). The
    # compiled binary dlopens that .so, so the wrapper LD_PRELOADs this shim:
    # EBUSY while the target thread is still running, join once it has exited.
    # Verified on a real OHOS device: resolveRenderLib() dlopen passes both
    # un-bundled and after `bun build --compile` embedding (2026-08-15).
    clang = formula_opt_bin("ohos-sdk")/"clang"
    (buildpath/"pthread_tryjoin_shim.c").write <<~C
      #define _GNU_SOURCE
      #include <pthread.h>
      #include <errno.h>

      /* OHOS SDK's pthread.h omits the declaration even though musl exports it. */
      extern int pthread_kill(pthread_t, int);

      int pthread_tryjoin_np(pthread_t thread, void **retval) {
        int rc = pthread_kill(thread, 0);
        if (rc == 0) return EBUSY;
        if (rc == ESRCH) return pthread_join(thread, retval);
        return rc;
      }
    C
    system clang, "-shared", "-fPIC", "-O2",
           "-o", "libpthread_tryjoin.so", "pthread_tryjoin_shim.c"
    libexec.install "libpthread_tryjoin.so"

    (bin/"opencode2").write <<~SH
      #!/bin/sh
      export LD_PRELOAD="#{opt_libexec}/libpthread_tryjoin.so${LD_PRELOAD:+:$LD_PRELOAD}"
      export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share-v2}"
      exec "#{opt_libexec}/bin/opencode2" "$@"
    SH
    chmod 0755, bin/"opencode2"

    # Completions from binary's --completions (always in sync).
    # base_name must be 'opencode2' not formula name (libexec binary).
    generate_completions_from_executable(libexec/"bin/opencode2", "--completions",
                                         base_name: "opencode2")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode2 --version 2>&1")
  end
end
