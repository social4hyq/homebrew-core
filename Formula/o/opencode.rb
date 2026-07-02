class Opencode < Formula
  desc "AI coding agent terminal UI — HarmonyOS aarch64"
  homepage "https://github.com/anomalyco/opencode"
  url "https://gh-proxy.com/https://github.com/anomalyco/opencode.git",
      revision: "10c894bdeef3618f5666fb506ef7f9491bb964d8"
  version "1.17.13"
  license "MIT"
  revision 1

  livecheck do
    url "https://github.com/anomalyco/opencode/releases/latest"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-v1.17.13-r4"
    rebuild 0
    sha256 cellar: :any_skip_relocation, arm64_ohos: "519976bb771280e7cd41d75bfd0c9a03e7269642dd609eff129fef980a64d50b"
  end

  # opencode is a `bun build --compile` single binary with bun runtime + JS + native .node/.so
  # all embedded and pre-signed. The bottle has zero runtime dependencies.
  depends_on "bun"               => :build
  depends_on "bun-pty"           => :build
  depends_on "lightningcss"      => :build
  depends_on "node"              => :build # npm_config_nodedir for bun install
  depends_on "ohos-sdk"          => :build # binary-sign-tool + llvm-objcopy (strips .codesign before re-sign)
  depends_on "python@3.14"       => :build
  depends_on "tailwindcss-oxide" => :build

  patch :p1 do
    file "Patches/opencode/build-ohos-target.patch"
  end
  patch :p1 do
    file "Patches/opencode/project-global-worktree.patch"
  end
  patch :p1 do
    # upstream bun.lock (generated on Linux) records 5 openharmony bindings as
    # `"os": "none"` because upstream bun doesn't recognize the openharmony
    # platform. The patched bun 1.4.0 (pr5-ohos-runtime/resolver_hooks.rs.patch)
    # already understands openharmony, but bun install uses the lockfile
    # fast-path and skips any package whose recorded `os` doesn't match
    # `OperatingSystem::CURRENT`. This patch rewrites those 5 entries'
    # metadata so the fast-path installs them. Re-generate with:
    #   sed -i -E '/^    "[^"]*openharmony-arm64":/ s/"os": "none"/"os": "openharmony"/' bun.lock
    file "Patches/opencode/bun-lock-openharmony-os.patch"
  end
  def install
    ENV["PYTHON"] = Formula["python@3.14"].opt_bin/"python3"
    ENV["npm_config_nodedir"] = Formula["node"].opt_prefix.to_s
    ENV["BUN_TMPDIR"] = (buildpath/".bun-tmp").to_s
    # Persistent bun cache (buildpath is wiped each run, causing network-failed packages to be re-downloaded
    # every time; place it under HOMEBREW_CACHE).
    ENV["BUN_INSTALL_CACHE"] = (HOMEBREW_CACHE/"bun-install-cache").to_s

    # Remove workspace packages not needed for the CLI build.
    # - desktop: Electron app (pulls electron-builder / app-builder-bin, requires GitHub release assets)
    # - web: Astro marketing site (pulls astro → older shiki@3.x / fontkit via npmjs.org)
    # - docs: documentation site
    # - storybook: UI component explorer (additional heavy deps)
    rm_rf "packages/desktop"
    rm_rf "packages/web"
    rm_rf "packages/docs"
    rm_rf "packages/storybook"

    system "bun", "install", "--ignore-scripts"

    # build.ts defaults to running `bun install --os=* --cpu=*` to pull all-platform native variants, but it
    # depends on Bun.$ → on OHOS, sh cannot exec bun from PATH (EPERM), so we pass --skip-install to skip the
    # internal version in build.ts and invoke it directly here, avoiding the broken $ path.
    # @ff-labs/fff-bun is pure TypeScript (no native binaries), so --os=* is a no-op and triggers
    # catalog re-resolution failures when npm cache is empty; omit it.
    cd "packages/opencode" do
      system "bun", "install", "--os=*", "--cpu=*", "@opentui/core@0.3.4"
      system "bun", "install", "--os=*", "--cpu=*", "@parcel/watcher@2.5.1"
    end

    sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    # llvm-objcopy from ohos-sdk (LLVM 15) — ELF section ops stable across LLVM 15-21.
    # (Formerly depended on llvm@21; dependency removed in slim-llvm21-bottle change.)
    objcopy   = Formula["ohos-sdk"].opt_prefix/"native/llvm/bin/llvm-objcopy"

    deploy_native = lambda do |src, dest|
      cp src, dest
      system sign_tool, "sign", "-selfSign", "1", "-inFile", dest, "-outFile", dest
      chmod 0755, dest
    end

    Dir.glob("node_modules/**/*.{so,node}", File::FNM_DOTMATCH).each do |f|
      next unless File.file?(f)
      next if File.symlink?(f)
      next if File.binread(f, 4) != "\x7fELF"

      system sign_tool, "sign", "-selfSign", "1", "-inFile", f, "-outFile", f
      chmod 0755, f
    end

    pty_so = Formula["bun-pty"].opt_lib/"librust_pty.so"
    pty_names = %w[librust_pty_arm64_musl.so librust_pty_arm64.so librust_pty.so]
    Dir.glob("node_modules/**/bun-pty/rust-pty/target/release", File::FNM_DOTMATCH).each do |d|
      pty_names.each do |n|
        deploy_native.call(pty_so, "#{d}/#{n}")
      end
    end

    lcss_so = Formula["lightningcss"].opt_lib/"liblightningcss_node.so"
    lcss_names = %w[lightningcss.linux-arm64-ohos.node
                    lightningcss.openharmony-arm64.node
                    lightningcss.linux-arm64-musl.node]
    Dir.glob("node_modules/**/lightningcss", File::FNM_DOTMATCH).each do |d|
      next unless File.directory?(d)

      lcss_names.each do |n|
        deploy_native.call(lcss_so, "#{d}/#{n}")
      end
      loader = "#{d}/node/index.js"
      next unless File.exist?(loader)

      content = File.read(loader)
      next if content.include?("process.platform === 'openharmony'")

      lcss_pattern = /^let parts = \[process\.platform, process\.arch\];\nif \(process\.platform === 'linux'\) \{/
      File.write(loader, content.sub(
                           lcss_pattern,
        "let parts = [process.platform, process.arch];\n" \
        "if (process.platform === 'openharmony') {\n  " \
        "parts = ['linux', process.arch, 'ohos'];\n" \
        "} else if (process.platform === 'linux') {",
                         ))
    end

    tw_so = Formula["tailwindcss-oxide"].opt_lib/"libtailwind_oxide.so"
    Dir.glob("node_modules/**/@tailwindcss/oxide", File::FNM_DOTMATCH).each do |d|
      deploy_native.call(tw_so, "#{d}/tailwindcss-oxide.linux-arm64-musl.node")
      loader = "#{d}/index.js"
      next unless File.exist?(loader)

      content = File.read(loader)
      next if content.include?("process.platform === 'openharmony'")

      # isMusl(): treat openharmony as musl
      content = content.sub(
        "if (process.platform === 'linux') {\n    musl = isMuslFromFilesystem()",
        "if (process.platform === 'linux' || process.platform === 'openharmony') {\n    " \
        "if (process.platform === 'openharmony') return true\n    " \
        "musl = isMuslFromFilesystem()",
      )
      # requireNative(): match openharmony alongside linux
      content = content.sub(
        "} else if (process.platform === 'linux') {",
        "} else if (process.platform === 'linux' || process.platform === 'openharmony') {",
      )
      File.write(loader, content)
    end

    # rollup: @rollup/rollup-openharmony-arm64@4.60.4 is an official upstream binding,
    # installed automatically by `bun install` (bun-lock-openharmony-os.patch flips its
    # lockfile `os` from "none" to "openharmony"). Its rollup.openharmony-arm64.node
    # gets ELF-signed by the generic .so/.node loop above; rollup's native.js falls back
    # to `require('@rollup/rollup-openharmony-arm64')` when dist/*.node is absent.

    # @opentui/core@0.3.4 bundle patches (libopentui.so was already ELF-signed by the
    # generic .so/.node signing loop above):
    # (1) drop stray uppercase-hex line before the trailing `//# sourceMappingURL=` — an
    #     upstream bundler bug leaves a partial debugId duplicate that bun 1.4.0's strict-mode
    #     parser rejects as "Decimal integer literals with a leading zero...";
    # (2) map openharmony-arm64 to @opentui/core-linux-arm64 (libopentui.so is Linux/musl-ABI
    #     compatible via the LLD-CodeSign patched linker).
    Dir.glob("node_modules/**/@opentui/core", File::FNM_DOTMATCH).each do |d|
      Dir.glob("#{d}/index-*.js").each do |bundle|
        next if bundle.end_with?(".map")

        content = File.read(bundle)
        next unless content.include?("resolveNativePackage")

        changed = false
        # Fix 1: strip orphan hex line immediately before sourceMappingURL comment.
        new_content = content.sub(%r{\n[0-9A-F]{20,}\n(?=//# (?:debugId|sourceMappingURL)=)}, "\n")
        if new_content != content
          content = new_content
          changed = true
        end
        # Fix 2: add openharmony branch (idempotent).
        unless content.include?("process.platform === \"openharmony\"")
          ohos_branch = <<~JS.chomp
            if (process.platform === "openharmony" && process.arch === "arm64") {
                return await import("@opentui/core-linux-arm64");
              }
              throw new Error(`opentui is not supported on the current platform:
          JS
          content = content.sub(
            "throw new Error(`opentui is not supported on the current platform:",
            ohos_branch,
          )
          changed = true
        end
        File.write(bundle, content) if changed
      end
    end

    # Bun runtime symlink: Bun.build({compile: {target: "bun-linux-arm64-musl"}}) expects a local bun
    bun_runtime = buildpath/"packages/opencode/bun-linux-aarch64-musl-v1.4.0"
    ln_sf Formula["bun"].opt_bin/"bun", bun_runtime

    cd "packages/opencode" do
      version = JSON.parse(File.read("package.json"))["version"]
      ENV["OPENCODE_VERSION"] = version
    end

    # 1) Pre-build the Web UI (vite → rolldown-vite)
    system "bun", "run", "--cwd", "packages/app", "build"

    # 2) bun compile + embed Web UI (SKIP_VITE_BUILD=1 skips the second vite invocation inside build.ts)
    cd "packages/opencode" do
      ENV["SKIP_VITE_BUILD"] = "1"
      system "bun", "run", "script/build.ts", "--single", "--skip-install"
    end

    # 3) Strip the embedded .codesign section, then re-sign with binary-sign-tool
    out = "packages/opencode/dist/opencode-openharmony-arm64-musl/bin/opencode"
    odie "opencode binary missing" unless File.exist?(out)
    unsigned = "#{out}.unsigned"
    stripped = "#{out}.stripped"
    mv out, unsigned
    system objcopy, "--remove-section", ".codesign", unsigned, stripped
    system sign_tool, "sign", "-selfSign", "1", "-inFile", stripped, "-outFile", out
    chmod 0755, out
    rm unsigned
    rm stripped
    bin.install out => "opencode"
    # Stub xdg-open so `opencode web` can spawn it without ENOENT on OHOS.
    (bin/"xdg-open").write "#!/bin/sh\nexit 0\n"
    chmod 0755, bin/"xdg-open"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode --version 2>&1")
  end
end
