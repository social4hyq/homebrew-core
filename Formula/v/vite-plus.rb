class VitePlus < Formula
  desc "Unified toolchain and entry point for web development"
  homepage "https://viteplus.dev"
  url "https://github.com/voidzero-dev/vite-plus/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "2ae9ff19a0c514e55ba76f4025cead2faff67c91da7dce152c60b71a040e5192"
  license "MIT"
  revision 9
  head "https://github.com/voidzero-dev/vite-plus.git", branch: "main"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/vite-plus-v1.0.0-r13"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b2c68a455a5d39430f53dd2d623b26c9221ad0b3d7135cb18c32ae05fe77d201"
  end

  depends_on "cmake" => :build
  depends_on "just" => :build
  # OHOS: @napi-rs/cli cross-compiles the bundled bindings against the SDK.
  depends_on "ohos-sdk" => :build
  depends_on "pkgconf" => :build
  depends_on "pnpm" => :build
  depends_on "rust" => :build
  depends_on "node"
  depends_on "sqlite"

  resource "rolldown" do
    url "https://github.com/rolldown/rolldown.git",
        revision: "8df421985114ecfaf52cce038d4a5a6ea8c05408"
    version "8df421985114ecfaf52cce038d4a5a6ea8c05408"

    livecheck do
      url "https://raw.githubusercontent.com/voidzero-dev/vite-plus/refs/tags/v#{LATEST_VERSION}/packages/tools/.upstream-versions.json"
      strategy :json do |json|
        json.dig("rolldown", "hash")
      end
    end
  end

  resource "vite" do
    url "https://github.com/vitejs/vite.git",
        revision: "39ddf7ccf7e7469ff6a3ba37bca38c32ea804d6e"
    version "39ddf7ccf7e7469ff6a3ba37bca38c32ea804d6e"

    livecheck do
      url "https://raw.githubusercontent.com/voidzero-dev/vite-plus/refs/tags/v#{LATEST_VERSION}/packages/tools/.upstream-versions.json"
      strategy :json do |json|
        json.dig("vite", "hash")
      end
    end
  end

  resource "vite-task-src" do
    url "https://github.com/voidzero-dev/vite-task.git",
        revision: "7d69d6577ecf6bd83deee32186de59918a712873"
    version "7d69d6577ecf6bd83deee32186de59918a712873"

    patch :p1 do
      file "Patches/vite-plus/0003-vite-task-fspy-ohos.patch"
    end
  end

  resource "wasm-tools-linux-arm64-musl" do
    url "https://registry.npmjs.org/@napi-rs/wasm-tools-linux-arm64-musl/-/wasm-tools-linux-arm64-musl-1.1.0.tgz"
    sha256 "ebeb7f019264d53ec50392e8f550c15bf9f9b474687694c62d18119520ce93f4"
  end

  resource "lzma-linux-arm64-musl" do
    url "https://registry.npmjs.org/@napi-rs/lzma-linux-arm64-musl/-/lzma-linux-arm64-musl-1.4.5.tgz"
    sha256 "7b972be94dcada346a868a89fcd4808e93df1587d4f06666005073ffa2f62ebe"
  end

  resource "tar-linux-arm64-musl" do
    url "https://registry.npmjs.org/@napi-rs/tar-linux-arm64-musl/-/tar-linux-arm64-musl-1.1.0.tgz"
    sha256 "824ac914a4ef81cca48e97ddb2037dac318a3e0c563653c60ba2e6dfd7242f87"
  end

  patch :p1 do
    file "Patches/vite-plus/0001-package-manager-ohos-ports.patch"
  end

  patch :p1 do
    file "Patches/vite-plus/0002-managed-node-openharmony-platform.patch"
  end

  patch :p1 do
    file "Patches/vite-plus/0004-vite-task-patch-fspy.patch"
  end

  patch :p1 do
    file "Patches/vite-plus/0005-ohos-ports-overrides.patch"
  end

  def install
    resource("rolldown").stage buildpath/"rolldown"
    resource("vite").stage buildpath/"vite"

    ENV["LIBSQLITE3_SYS_USE_PKG_CONFIG"] = "1"
    ENV["RUSTC_BOOTSTRAP"] = "1" # workaround to build with stable rust

    # Build with Homebrew pnpm. The staged resources pin their own versions too
    %w[package.json rolldown/package.json vite/package.json].each do |file|
      package_json = buildpath/file
      package_json.atomic_write(JSON.pretty_generate(JSON.parse(package_json.read).except("packageManager")))
    end

    # Align the staged Vite's Vitest versions with the lockfile, as upstream CI does
    system "node", "packages/tools/src/vendored-vitest.ts"

    # Vite patches only build-time dependencies, which the production deploy below omits
    (buildpath/"pnpm-workspace.yaml").append_lines "allowUnusedPatches: true"

    # The @napi-rs shims (patch 0005) wrap their linux-arm64-musl twins, which
    # share OHOS's libc family
    {
      "@napi-rs-wasm-tools-1.1.0" => ["wasm-tools.node", "wasm-tools-linux-arm64-musl"],
      "@napi-rs-lzma-1.4.5"       => ["lzma.node", "lzma-linux-arm64-musl"],
      "@napi-rs-tar-1.1.0"        => ["tar.node", "tar-linux-arm64-musl"],
    }.each do |dir, (node_file, resource_name)|
      resource(resource_name).stage do
        node_src = Dir.glob("**/*.node").first
        odie "no .node in the musl resource #{resource_name}" if node_src.nil?
        cp node_src, buildpath/"ohos-shims"/dir/node_file
      end
    end

    # @napi-rs/cli builds the ohos linker/cc/ar paths from this.
    ENV["OHOS_SDK_NATIVE"] = "#{formula_opt_prefix("ohos-sdk")}/native"

    # Patch 0004 points fspy at this checkout, at ../vite-task.
    vt_dir = buildpath.parent/"vite-task"
    rm_r vt_dir if vt_dir.exist?
    resource("vite-task-src").stage vt_dir

    # Upstream CI brands the staged Vite before building it; without this vp
    # prints Vite's own native config loader notice and the VITE banner.
    system "pnpm", "exec", "tool", "brand-vite"

    system "just", "build"
    system "cargo", "install", *std_cargo_args(path: "crates/vp_global_cli")

    # No --no-optional: it prunes optionalDependencies wholesale, taking
    # oxfmt's and oxlint's openharmony bindings with them. pnpm already filters
    # them by os/cpu, so the flag only cost us those bindings.
    system "pnpm", "--filter=vite-plus", "deploy", "--prod", "--legacy",
           prefix/"node_modules/vite-plus"
    node_modules = prefix/"node_modules/vite-plus/node_modules"
    # Remove incompatible pre-built `bare-*` binaries. Recurse as `deploy --legacy` writes
    # both the legacy `<name>@<version>` and the current `@/<name>/<version>/<hash>` layouts
    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    node_modules.glob(".pnpm/**/prebuilds/*")
                .each { |dir| rm_r(dir) if dir.basename.to_s != "#{os}-#{arch}" }
    rm_r node_modules.glob(".pnpm/**/node_modules/fsevents")

    # /tmp is read-only and vp's default ShimMode "managed" wants a node that
    # OHOS will exec; write_env_script cannot express either, hence the wrapper.
    # The real binary sits one level below prefix so <dir>/../node_modules
    # still resolves.
    odie "cargo install did not produce bin/vp" unless (bin/"vp").exist?
    libexec.mkpath
    mv bin/"vp", libexec/"vp"
    (bin/"vp").write <<~SH
      #!/bin/sh
      TMPDIR_DEFAULT="#{HOMEBREW_PREFIX}/var/cache"
      export TMPDIR="${TMPDIR:-$TMPDIR_DEFAULT}"
      export TMP="${TMP:-$TMPDIR}"
      mkdir -p "$TMPDIR" 2>/dev/null
      if [ -n "$HOME" ] && [ ! -f "$HOME/.vite-plus/config.json" ]; then
        mkdir -p "$HOME/.vite-plus" 2>/dev/null &&
          printf '{"shimMode":"system_first"}\\n' > "$HOME/.vite-plus/config.json" 2>/dev/null
      fi
      exec "#{libexec}/vp" "$@"
    SH
    chmod 0755, bin/"vp"

    # Symlink vp to vpr and vpx. These are detected at runtime by argv[0]
    bin.install_symlink bin/"vp" => "vpr"
    bin.install_symlink bin/"vp" => "vpx"

    # Generate shell completions, vp uses clap but with a custom env var so we can't use our helper
    (bash_completion/"vp").write Utils.safe_popen_read({ "VP_COMPLETE" => "bash" }, bin/"vp")
    (fish_completion/"vp.fish").write Utils.safe_popen_read({ "VP_COMPLETE" => "fish" }, bin/"vp")
    (zsh_completion/"_vp").write Utils.safe_popen_read({ "VP_COMPLETE" => "zsh" }, bin/"vp")
  end

  def caveats
    <<~EOS
      On OHOS, /tmp is read-only and vp's Rust install path creates tempdirs
      via TMPDIR. bin/vp is a wrapper that defaults TMPDIR to
      #{HOMEBREW_PREFIX}/var/cache when unset.

      vp's default ShimMode is "managed" (downloads official glibc Node.js
      binaries that OHOS refuses to exec). The wrapper seeds
      ~/.vite-plus/config.json with {"shimMode":"system_first"} on first
      run, so the system Node.js is preferred; delete that file to opt
      back into managed runtimes.
    EOS
  end

  test do
    # OHOS: /tmp is read-only, and HOME must point at testpath so the
    # wrapper's first-run config seeding lands here
    ENV["TMPDIR"] = testpath/"tmp"
    mkdir_p ENV["TMPDIR"]
    ENV["HOME"] = testpath.to_s

    # Use Homebrew node and skip the first-run setup prompt, which stops `vp` on the test PTY
    ENV["VP_NODE_MANAGER"] = "no"

    assert_match version.to_s, shell_output("#{bin}/vp --version")

    # `vp` calls `tcsetattr` on a tty stdin, which stops it with SIGTTOU on the test PTY
    system "#{bin}/vp create vite:application --no-interactive --directory test-app < /dev/null"
    assert_path_exists testpath/"test-app/package.json"
  end
end
