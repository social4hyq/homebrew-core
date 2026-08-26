class VitePlus < Formula
  require "yaml"

  desc "Unified toolchain and entry point for web development"
  homepage "https://viteplus.dev"
  url "https://github.com/voidzero-dev/vite-plus/archive/refs/tags/v0.2.8.tar.gz"
  sha256 "c07ae8f828039fae32b791abcfc8f1d1b769024a2ae5c04bdc2946e8318615f4"
  license "MIT"

  # OHOS delta vs upstream (everything else is verbatim):
  # bottle block, depends_on swaps, overrides/env/wrapper fences below.
  revision 1
  head "https://github.com/voidzero-dev/vite-plus.git", branch: "main"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/vite-plus-v0.2.8-r3"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2091fab5bb77237256f488c80af44ddfa33003aa96a5e40f0dfed4c0fa073211"
  end

  depends_on "cmake" => :build
  depends_on "just" => :build
  # OHOS: no rustup formula; stable rust + RUSTC_BOOTSTRAP (see install).
  depends_on "ohos-sdk" => :build
  depends_on "pnpm@10" => :build
  depends_on "rust" => :build # TODO: try to restore rustup: https://github.com/voidzero-dev/vite-task/commit/db99ba4d5d33323cc9e7b329f11bdea0610fbc7f
  # OHOS: @napi-rs/cli cross-compiles the bundled bindings against the SDK.
  # OHOS: pnpm >= 11.23 regressed `deploy --legacy` (pnpm/pnpm#14130); the
  # build runs under pnpm@10, runtime keeps the unversioned pnpm.
  depends_on "node"

  resource "rolldown" do
    url "https://github.com/rolldown/rolldown.git",
        revision: "872b98ac7476eb7d5892a2913e4ba010d124c6ac"
    version "872b98ac7476eb7d5892a2913e4ba010d124c6ac"

    livecheck do
      url "https://raw.githubusercontent.com/voidzero-dev/vite-plus/refs/tags/v#{LATEST_VERSION}/packages/tools/.upstream-versions.json"
      strategy :json do |json|
        json.dig("rolldown", "hash")
      end
    end
  end

  resource "vite" do
    url "https://github.com/vitejs/vite.git",
        revision: "fa79f9ab699f9a22a6f9b50f3d247be6b51f684d"
    version "fa79f9ab699f9a22a6f9b50f3d247be6b51f684d"

    livecheck do
      url "https://raw.githubusercontent.com/voidzero-dev/vite-plus/refs/tags/v#{LATEST_VERSION}/packages/tools/.upstream-versions.json"
      strategy :json do |json|
        json.dig("vite", "hash")
      end
    end
  end

  # OHOS: vendored vite-task patched for the ohos target env (see install).
  resource "vite-task" do
    url "https://github.com/voidzero-dev/vite-task.git",
        revision: "5c1d02c750ac21c6f4cf0528062590a145e87fd1"
    version "5c1d02c750ac21c6f4cf0528062590a145e87fd1"
  end

  def install
    resource("rolldown").stage buildpath/"rolldown"
    resource("vite").stage buildpath/"vite"

    # --- OHOS: pnpm overrides for native bindings --------------------------
    # Most napi packages now publish openharmony-arm64 builds at the exact
    # versions this lockfile pins (rolldown/oxfmt/oxlint/oxc-*/rollup — pnpm
    # installs those natively). The exceptions below are aliased: missing
    # openharmony builds reuse the linux-arm64-musl twins (same libc/ABI
    # family) or the @ohos-ports community ports. Bottle signing is handled
    # by the pipeline's automatic ELF pass, not here.
    workspace_yaml = buildpath/"pnpm-workspace.yaml"
    ws = YAML.safe_load(workspace_yaml.read)
    ws["overrides"] = {
      # loader-patched drop-in with a prebuilt ohos binding
      "lightningcss"                             => "npm:@ohos-ports/lightningcss@1.33.0-1",
      # bare-binding port packages (main points at the .node)
      "@parcel/watcher-openharmony-arm64"        => "npm:@ohos-ports/parcel-watcher-openharmony-arm64@2.5.1",
      # musl twins for packages with no openharmony build at any version
      "@yuku-codegen/binding-openharmony-arm64"  => "npm:@yuku-codegen/binding-linux-arm64-musl@0.5.44",
      "@yuku-parser/binding-openharmony-arm64"   => "npm:@yuku-parser/binding-linux-arm64-musl@0.5.44",
      "@ast-grep/napi-openharmony-arm64"         => "npm:@ast-grep/napi-linux-arm64-musl@0.43.0",
      "@unrs/resolver-binding-openharmony-arm64" => "npm:@unrs/resolver-binding-linux-arm64-musl@1.11.1",
      # @napi-rs/cli (build tooling) optional tool deps
      "@napi-rs/wasm-tools-openharmony-arm64"    => "npm:@napi-rs/wasm-tools-linux-arm64-musl@1.0.1",
      "@napi-rs/lzma-openharmony-arm64"          => "npm:@napi-rs/lzma-linux-arm64-musl@1.4.5",
      "@napi-rs/tar-openharmony-arm64"           => "npm:@napi-rs/tar-linux-arm64-musl@1.1.0",
    }.merge(ws["overrides"] || {})
    File.write(workspace_yaml, YAML.dump(ws))
    # -----------------------------------------------------------------------

    # --- OHOS: build environment -------------------------------------------
    # pnpm >= 11.20 verifies the engine binary when delegating to a
    # packageManager pin; no openharmony @pnpm/exe exists. Same workaround
    # as Alpine packaging.
    ENV["NPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS"] = "false"
    ENV["npm_config_manage_package_manager_versions"] = "false"
    ENV.prepend_path "PATH", formula_opt_bin("pnpm@10")
    # Unlocks `-Z bindeps` (fspy preload artifact deps) on the stable
    # compiler; the repo's rust-toolchain.toml nightly pin is inert here.
    ENV["RUSTC_BOOTSTRAP"] = "1"
    # Direct crates.io access stalls on some networks; probe and fall back
    # to rsproxy only where needed (fast networks keep using crates.io).
    unless system "curl", "-fsIL", "--max-time", "8", "-o", File::NULL,
                  "https://index.crates.io/config.json"
      ENV["CARGO_REGISTRIES_CRATES_IO_INDEX"] = "sparse+https://rsproxy.cn/index/"
    end
    # @napi-rs/cli builds the ohos linker/cc/ar paths from this.
    ENV["OHOS_SDK_NATIVE"] = "#{formula_opt_prefix("ohos-sdk")}/native"
    # -----------------------------------------------------------------------

    # --- OHOS: vendored vite-task patch ------------------------------------
    # fspy_preload_unix (git dep) compiles as an empty crate on musl, where
    # seccomp alone handles access tracking; extend the exemption to ohos,
    # whose libc lacks the statx/execveat bindings it needs. Staged outside
    # the workspace dir: a nested workspace inside the tree derails cargo's
    # workspace-root selection.
    vt_dir = HOMEBREW_CACHE/"vite-plus-vite-task"
    unless (vt_dir/".git").exist?
      rm_r(vt_dir) if vt_dir.exist?
      resource("vite-task").stage vt_dir
    end
    preload_lib = vt_dir/"crates/fspy_preload_unix/src/lib.rs"
    ohos_exemption = 'all(unix, not(target_env = "musl"), not(target_env = "ohos"))'
    unless preload_lib.read.include?(ohos_exemption)
      inreplace preload_lib,
                'all(unix, not(target_env = "musl"))',
                ohos_exemption
    end
    patched_crates = %w[
      fspy pty_terminal_test pty_terminal_test_client snapshot_test
      vite_path vite_powershell vite_select vite_str vite_task vite_workspace
    ]
    patch_block = <<~TOML
      [patch."https://github.com/voidzero-dev/vite-task.git"]
      #{patched_crates.map { |c| %Q(#{c} = { path = "#{vt_dir}/crates/#{c}" }) }.join("\n")}
    TOML
    cargo_toml = buildpath/"Cargo.toml"
    File.write(cargo_toml, "#{File.read(cargo_toml)}\n#{patch_block}")
    # ----------------------------------------------------------------------

    system "just", "build"
    system "cargo", "install", *std_cargo_args(path: "crates/vite_global_cli")

    system "pnpm", "--filter=vite-plus", "deploy", "--prod", "--legacy", "--no-optional",
           prefix/"node_modules/vite-plus"
    node_modules = prefix/"node_modules/vite-plus/node_modules"
    rm_r node_modules.glob(".pnpm/*/node_modules/*/prebuilds/{darwin,ios}-x64*")
    rm_r node_modules.glob(".pnpm/fsevents@*/node_modules/fsevents")

    # --- OHOS: bin/vp wrapper ----------------------------------------------
    # vp's Rust install path creates tempdirs via TMPDIR (defaults to the
    # read-only /tmp), and its default ShimMode is "managed" — it downloads
    # official glibc Node.js binaries that OHOS refuses to exec (verified
    # EACCES with a raw binary and a fresh HOME). The wrapper defaults
    # TMPDIR if unset and seeds the system_first config on first run.
    # write_env_script cannot express either (unconditional exports only).
    # The real binary sits one level below prefix so <dir>/../node_modules
    # still resolves to the prefix/node_modules deploy target.
    odie "cargo install did not produce bin/vp" unless (bin/"vp").exist?
    mv bin/"vp", libexec/"vp"
    (bin/"vp").write <<~SH
      #!/bin/sh
      TMPDIR_DEFAULT="#{HOMEBREW_PREFIX}/var/cache"
      export TMPDIR="${TMPDIR:-$TMPDIR_DEFAULT}"
      mkdir -p "$TMPDIR" 2>/dev/null
      if [ -n "$HOME" ] && [ ! -f "$HOME/.vite-plus/config.json" ]; then
        mkdir -p "$HOME/.vite-plus" 2>/dev/null &&
          printf '{"shimMode":"system_first"}\\n' > "$HOME/.vite-plus/config.json" 2>/dev/null
      fi
      exec "#{libexec}/vp" "$@"
    SH
    chmod 0755, bin/"vp"
    # ----------------------------------------------------------------------

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
    # OHOS: writable TMPDIR (read-only /tmp) and HOME pointed at testpath so
    # the wrapper's first-run config seeding lands here.
    ENV["TMPDIR"] = testpath/"tmp"
    mkdir_p ENV["TMPDIR"]
    ENV["HOME"] = testpath.to_s

    assert_match version.to_s, shell_output("#{bin}/vp --version")

    # OHOS: vp create/fmt hit transient exec/FS-settle ENOENTs under load;
    # retry before giving up (cf. herdr's sign-retry loop).

    system bin/"vp", "create", "vite:application", "--no-interactive", "--directory", "test-app"
    assert_path_exists testpath/"test-app/package.json"

    # OHOS: the scaffolded app resolves vite-plus from the npm registry,
    # which ships no openharmony bindings. Wire it the same way an end user
    # would — pnpm-workspace override to the @ohos-npm-ports port (loader
    # patched, prebuilt ohos binding in-package) plus @rolldown's native
    # openharmony binding for vite-plus-core's bundled loader, and drop the
    # scaffold's `prepare: vp config` hook, which runs before install can
    # fetch those bindings. The scaffold's workspace file already has an
    # overrides section (vite: catalog:), so merge into it.
    pkg_json = testpath/"test-app/package.json"
    manifest = JSON.parse(pkg_json.read)
    manifest["scripts"].delete("prepare")
    File.write(pkg_json, JSON.pretty_generate(manifest) << "\n")

    workspace = testpath/"test-app/pnpm-workspace.yaml"
    ws = YAML.safe_load(workspace.read)
    ws["overrides"] = {
      "vite-plus"                           => "npm:@ohos-npm-ports/vite-plus@0.2.8-1",
      "@rolldown/binding-openharmony-arm64" => "npm:@rolldown/binding-openharmony-arm64@1.2.2",
    }.merge(ws["overrides"] || {})
    File.write(workspace, YAML.dump(ws))

    cd testpath/"test-app" do
      output = shell_output("#{bin}/vp fmt")
      assert_match "Finished", output
    end
  end
end
