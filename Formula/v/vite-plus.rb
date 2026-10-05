class VitePlus < Formula
  require "json"
  require "yaml"

  desc "Unified toolchain and entry point for web development"
  homepage "https://viteplus.dev"
  url "https://github.com/voidzero-dev/vite-plus/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "2ae9ff19a0c514e55ba76f4025cead2faff67c91da7dce152c60b71a040e5192"
  license "MIT"
  revision 5
  head "https://github.com/voidzero-dev/vite-plus.git", branch: "main"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/vite-plus-v1.0.0-r9"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "94af69444b375a147872725b276cca62cd4a88f53906e1fe383b06c850f71c03"
  end

  # OHOS-only blocks are fenced below; everything else tracks upstream.

  depends_on "cmake" => :build
  depends_on "just" => :build
  # OHOS: @napi-rs/cli cross-compiles the bundled bindings against the SDK.
  depends_on "ohos-sdk" => :build
  depends_on "pnpm" => :build
  depends_on "rustup" => :build # TODO: try to restore stable rust: https://github.com/voidzero-dev/vite-task/commit/db99ba4d5d33323cc9e7b329f11bdea0610fbc7f
  depends_on "node"

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

  # OHOS: vendored vite-task, for the fspy_preload_unix gate (see install).
  resource "vite-task-src" do
    url "https://github.com/voidzero-dev/vite-task.git",
        revision: "7d69d6577ecf6bd83deee32186de59918a712873"
    version "7d69d6577ecf6bd83deee32186de59918a712873"
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

  # OHOS: download pnpm/bun from the @ohos-npm-ports ports (see the patch file).
  patch :p1 do
    file "Patches/vite-plus/0001-package-manager-ohos-ports.patch"
  end

  # OHOS: managed-Node platform string (see the patch file for the rationale).
  patch :p1 do
    file "Patches/vite-plus/0002-managed-node-openharmony-platform.patch"
  end

  def install
    resource("rolldown").stage buildpath/"rolldown"
    resource("vite").stage buildpath/"vite"

    # Build with Homebrew pnpm. The staged resources pin their own versions too
    %w[package.json rolldown/package.json vite/package.json].each do |file|
      package_json = buildpath/file
      package_json.atomic_write(JSON.pretty_generate(JSON.parse(package_json.read).except("packageManager")))
    end

    # Align the staged Vite's Vitest versions with the lockfile, as upstream CI does
    system "node", "packages/tools/src/vendored-vitest.ts"

    # Vite patches only build-time dependencies, which the production deploy below omits
    (buildpath/"pnpm-workspace.yaml").append_lines "allowUnusedPatches: true"

    shims_dir = buildpath/"ohos-shims"
    # Packages with an openharmony build in-package are remapped by override.
    # The three @napi-rs shims below have no such build; their linux-arm64-musl
    # twins share OHOS's libc family, so the shim renames the binding to what
    # the loaders ask for. Build-time only — bottle signing is the pipeline's.
    # [parent package, version, binding file name the loaders require,
    #  Homebrew resource]
    shims = [
      ["@napi-rs/wasm-tools", "1.1.0", "wasm-tools.node", "wasm-tools-linux-arm64-musl"],
      ["@napi-rs/lzma",       "1.4.5", "lzma.node",       "lzma-linux-arm64-musl"],
      ["@napi-rs/tar",        "1.1.0", "tar.node",        "tar-linux-arm64-musl"],
    ]
    overrides = {
      "lightningcss"          => "npm:@ohos-npm-ports/lightningcss@1.33.0-1",
      # All three yuku versions load a binding: 0.9.3 at runtime, 0.8.7/0.10.2
      # at build time via rolldown-plugin-dts. Keys must carry the version --
      # yuku appears under several ranges in one graph.
      "yuku-codegen@0.8.7"    => "npm:@ohos-npm-ports/yuku-codegen@0.8.7-1",
      "yuku-codegen@0.9.3"    => "npm:@ohos-npm-ports/yuku-codegen@0.9.3-1",
      "yuku-codegen@0.10.2"   => "npm:@ohos-npm-ports/yuku-codegen@0.10.2-1",
      "yuku-parser@0.8.7"     => "npm:@ohos-npm-ports/yuku-parser@0.8.7-1",
      "yuku-parser@0.9.3"     => "npm:@ohos-npm-ports/yuku-parser@0.9.3-1",
      "yuku-parser@0.10.2"    => "npm:@ohos-npm-ports/yuku-parser@0.10.2-1",
      "@ast-grep/napi@0.43.0" => "npm:@ohos-npm-ports/ast-grep-napi@0.43.0-1",
      # Bare key: packages/cli declares this via catalog:, where a
      # version-qualified selector does not match.
      "oxlint-tsgolint"       => "npm:@ohos-npm-ports/oxlint-tsgolint@7.0.2003-1",
    }
    extensions = {}
    shims.each do |parent, version, node_file, resource_name|
      ohos_name = "#{parent}-openharmony-arm64"
      shim = shims_dir/"#{parent.tr("/", "-")}-#{version}"

      shim.mkpath
      resource(resource_name).stage do
        node_src = Dir.glob("**/*.node").first
        odie "no .node in musl resource for #{parent}@#{version}" if node_src.nil?
        cp node_src, shim/node_file
      end
      (shim/"package.json").write <<~JSON
        {
          "name": "#{ohos_name}",
          "version": "#{version}",
          "main": "#{node_file}"
        }
      JSON
      extensions["#{parent}@#{version}"] = { "optionalDependencies" => { ohos_name => version } }
      overrides["#{ohos_name}@#{version}"] = "link:#{shim}"
    end
    # Embeds its openharmony binding in the package itself, so no graft needed.
    overrides["@parcel/watcher"] = "npm:@ohos-npm-ports/parcel-watcher@2.5.1-2"

    workspace_yaml = buildpath/"pnpm-workspace.yaml"
    ws = YAML.safe_load(workspace_yaml.read)
    ws["overrides"] = overrides.merge(ws["overrides"] || {})
    ws["packageExtensions"] = extensions.merge(ws["packageExtensions"] || {})
    # The 24h minimumReleaseAge gate would block a freshly published port; the
    # exact-version pins above are the trust decision instead.
    ws["minimumReleaseAgeExclude"] = (ws["minimumReleaseAgeExclude"] || []).push("@ohos-npm-ports/*")
    File.write(workspace_yaml, YAML.dump(ws))

    # pnpm >= 11.20 verifies the engine binary for a packageManager pin, and
    # no openharmony @pnpm/exe is published.
    ENV["NPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS"] = "false"
    ENV["npm_config_manage_package_manager_versions"] = "false"
    ENV.prepend_path "PATH", formula_opt_bin("pnpm")
    # Direct crates.io access stalls on some networks; probe and fall back
    # to rsproxy only where needed (fast networks keep using crates.io).
    unless system "curl", "-fsIL", "--max-time", "8", "-o", File::NULL,
                  "https://index.crates.io/config.json"
      ENV["CARGO_REGISTRIES_CRATES_IO_INDEX"] = "sparse+https://rsproxy.cn/index/"
    end
    # @napi-rs/cli builds the ohos linker/cc/ar paths from this.
    ENV["OHOS_SDK_NATIVE"] = "#{formula_opt_prefix("ohos-sdk")}/native"

    # fspy records a task's file accesses so a changed input invalidates the
    # cache. Its seccomp-unotify path cannot work here (HongMeng rejects
    # SECCOMP_RET_USER_NOTIF), so tracking has to come from fspy_preload_unix,
    # the LD_PRELOAD library fspy reaches through a -Z bindeps artifact
    # dependency. It builds on OHOS except for libc::statx and execveat, which
    # OHOS's libc lacks, so only those two interceptions are dropped (a libuv
    # statx still goes through the intercepted syscall()). The variadic
    # interceptions need c_variadic, stable on upstream's nightly but not on
    # this toolchain. Only this one crate is patched -- a [patch] entry for any
    # of the others turns it into a path source, and build.ts then cannot read
    # vt's cargo revision. A statically linked child would need the seccomp
    # path, so it is exec'd untracked instead of failing the exec.
    vt_dir = buildpath.parent/"vite-task"
    rm_r vt_dir if vt_dir.exist?
    resource("vite-task-src").stage vt_dir
    crate = vt_dir/"crates/fspy_preload_unix"
    odie "fspy_preload_unix not found in the staged checkout" unless crate.directory?
    inreplace crate/"src/lib.rs",
              "#[cfg(all(unix, not(target_env = \"musl\")))]\nmod client;",
              "#![cfg_attr(target_env = \"ohos\", feature(c_variadic))]\n\n" \
              "#[cfg(all(unix, not(target_env = \"musl\")))]\nmod client;"
    inreplace crate/"src/interceptions/stat.rs",
              "#[cfg(target_os = \"linux\")]\nintercept!(statx:",
              "#[cfg(all(target_os = \"linux\", not(target_env = \"ohos\")))]\nintercept!(statx:"
    inreplace crate/"src/interceptions/stat.rs",
              "#[cfg(target_os = \"linux\")]\nunsafe extern \"C\" fn statx(",
              "#[cfg(all(target_os = \"linux\", not(target_env = \"ohos\")))]\nunsafe extern \"C\" fn statx("
    inreplace crate/"src/interceptions/spawn/exec/mod.rs",
              "    intercept!(execveat(64):",
              "    #[cfg(not(target_env = \"ohos\"))]\n    intercept!(execveat(64):"
    inreplace crate/"src/interceptions/spawn/exec/mod.rs",
              "    unsafe extern \"C\" fn execveat(",
              "    #[cfg(not(target_env = \"ohos\"))]\n    unsafe extern \"C\" fn execveat("
    inreplace crate/"src/interceptions/spawn/exec/mod.rs",
              "                if let Some(pre_exec) = pre_exec {\n                    " \
              "pre_exec.run()?;\n                }\n",
              "                #[cfg(not(target_env = \"ohos\"))]\n                " \
              "if let Some(pre_exec) = pre_exec {\n                    " \
              "pre_exec.run()?;\n                }\n                " \
              "#[cfg(target_env = \"ohos\")]\n                let _ = pre_exec;\n"
    cargo_toml = buildpath/"Cargo.toml"
    File.write(cargo_toml, "#{File.read(cargo_toml)}\n" \
                           "[patch.\"https://github.com/voidzero-dev/vite-task.git\"]\n" \
                           "fspy_preload_unix = { path = \"#{crate}\" }\n")

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
