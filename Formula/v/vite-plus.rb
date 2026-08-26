class VitePlus < Formula
  require "json"
  require "yaml"

  desc "Unified toolchain and entry point for web development"
  homepage "https://viteplus.dev"
  url "https://github.com/voidzero-dev/vite-plus/archive/refs/tags/v0.2.8.tar.gz"
  sha256 "c07ae8f828039fae32b791abcfc8f1d1b769024a2ae5c04bdc2946e8318615f4"
  license "MIT"

  # OHOS delta vs upstream (everything else is verbatim):
  # bottle block, depends_on swaps, native-binding wiring, build env,
  # vite-task patch, bin/vp wrapper. See the fenced blocks in install.
  revision 1
  head "https://github.com/voidzero-dev/vite-plus.git", branch: "main"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/vite-plus-v0.2.8-r4"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3a32184511675fa84129810a70bb90a9a4e40f0b0999c1c7f422c4e207606773"
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

    # --- OHOS: native bindings ----------------------------------------------
    # Registry audit (openharmony-arm64 availability at the versions this
    # lockfile pins): @rolldown/binding 1.2.2, @oxfmt/binding 0.61.0,
    # @oxlint/binding 1.76.0, @oxc-parser/binding 0.142.0,
    # @oxc-resolver/binding 11.24.2 and @rollup/rollup 4.60.4 are published
    # natively — pnpm installs those with no help. The rest:
    #   * lightningcss has no openharmony build at any version, but the
    #     @ohos-ports community port is a loader-patched drop-in.
    #   * yuku-*, @ast-grep/napi and the @napi-rs/cli tool deps ship no
    #     openharmony build anywhere. Their linux-arm64-musl twins run on
    #     OHOS (same libc family), so fabricate local shim packages from
    #     the musl tarballs: the binding file is renamed to what the
    #     loaders require and `main` points straight at it, satisfying
    #     both bare (`require('<ohos-name>')`) and subpath
    #     (`require('<ohos-name>/<file>.node')`) loader conventions. The
    #     shims are grafted into the graph with packageExtensions (adds
    #     the openharmony optionalDependency the parents don't declare)
    #     and overrides (remaps it to the local shim) — one mechanism,
    #     applied identically to the build tree and, via pnpm deploy, to
    #     the deployed tree. Bottle signing is fully automatic (pipeline
    #     ELF pass); nothing signs here.
    shims_dir = buildpath/"ohos-shims"
    # [parent package, version, ohos binding package, musl binding package,
    #  binding file name the loaders require]
    shims = [
      ["yuku-codegen",    "0.5.44", "@yuku-codegen/binding", "yuku-codegen.node"],
      ["yuku-codegen",    "0.7.0",  "@yuku-codegen/binding", "yuku-codegen.node"],
      ["yuku-codegen",    "0.8.3",  "@yuku-codegen/binding", "yuku-codegen.node"],
      ["yuku-parser",     "0.5.44", "@yuku-parser/binding",  "yuku-parser.node"],
      ["yuku-parser",     "0.7.0",  "@yuku-parser/binding",  "yuku-parser.node"],
      ["yuku-parser",     "0.8.3",  "@yuku-parser/binding",  "yuku-parser.node"],
      ["@ast-grep/napi",  "0.43.0", "@ast-grep/napi",        "ast-grep-napi.node"],
      ["@napi-rs/wasm-tools", "1.0.1", "@napi-rs/wasm-tools", "wasm-tools.node"],
      ["@napi-rs/lzma",       "1.4.5", "@napi-rs/lzma",       "lzma.node"],
      ["@napi-rs/tar",        "1.1.0", "@napi-rs/tar",        "tar.node"],
    ]
    musl_tgz = lambda do |pkg, version|
      leaf = pkg.split("/").last
      tgz = HOMEBREW_CACHE/"vite-plus-musl-napi"/"#{pkg.tr("/", "-")}-#{version}.tgz"
      tgz.parent.mkpath
      unless tgz.exist?
        system "curl", "-fSL", "--retry", "5", "-o", tgz,
               "https://registry.npmmirror.com/#{pkg}-linux-arm64-musl/-/#{leaf}-linux-arm64-musl-#{version}.tgz"
      end
      tgz
    end
    overrides = {
      "lightningcss" => "npm:@ohos-ports/lightningcss@1.33.0-1",
    }
    extensions = {}
    shims.each do |parent, version, binding_pkg, node_file|
      ohos_name = "#{binding_pkg}-openharmony-arm64"
      shim = shims_dir/"#{parent.tr("/", "@")}-#{version}"
      next if shim.exist?

      shim.mkpath
      stage = shim/"stage"
      stage.mkpath
      system "tar", "xzf", musl_tgz.call(binding_pkg, version), "-C", stage
      node_src = Dir.glob("#{stage}/**/*.node").first
      odie "no .node in musl tarball for #{binding_pkg}@#{version}" if node_src.nil?
      cp node_src, shim/node_file
      rm_r stage
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
    # @parcel/watcher: the @ohos-ports port ships the openharmony binding
    # as a proper package (main points at the .node).
    extensions["@parcel/watcher@2.5.1"] = {
      "optionalDependencies" => { "@parcel/watcher-openharmony-arm64" => "2.5.1" },
    }
    overrides["@parcel/watcher-openharmony-arm64@2.5.1"] = "npm:@ohos-ports/parcel-watcher-openharmony-arm64@2.5.1"

    workspace_yaml = buildpath/"pnpm-workspace.yaml"
    ws = YAML.safe_load(workspace_yaml.read)
    ws["overrides"] = overrides.merge(ws["overrides"] || {})
    ws["packageExtensions"] = extensions.merge(ws["packageExtensions"] || {})
    File.write(workspace_yaml, YAML.dump(ws))
    # -------------------------------------------------------------------------

    # --- OHOS: build environment ---------------------------------------------
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
    # -------------------------------------------------------------------------

    # --- OHOS: vendored vite-task patch --------------------------------------
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
    # ------------------------------------------------------------------------

    system "just", "build"
    system "cargo", "install", *std_cargo_args(path: "crates/vite_global_cli")

    system "pnpm", "--filter=vite-plus", "deploy", "--prod", "--legacy", "--no-optional",
           prefix/"node_modules/vite-plus"
    node_modules = prefix/"node_modules/vite-plus/node_modules"
    rm_r node_modules.glob(".pnpm/*/node_modules/*/prebuilds/{darwin,ios}-x64*")
    rm_r node_modules.glob(".pnpm/fsevents@*/node_modules/fsevents")

    # --- OHOS: bin/vp wrapper ------------------------------------------------
    # vp's Rust install path creates tempdirs via TMPDIR (defaults to the
    # read-only /tmp), and its default ShimMode is "managed" — it downloads
    # official glibc Node.js binaries that OHOS refuses to exec (verified
    # EACCES with a raw binary and a fresh HOME). The wrapper defaults
    # TMPDIR if unset and seeds the system_first config on first run;
    # write_env_script cannot express either (unconditional exports only).
    # The real binary sits one level below prefix so <dir>/../node_modules
    # still resolves to the prefix/node_modules deploy target.
    odie "cargo install did not produce bin/vp" unless (bin/"vp").exist?
    libexec.mkpath
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
    vp_with_retry = lambda do |*args|
      max_attempts = 3
      (1..max_attempts).each do |attempt|
        system bin/"vp", *args
        break
      rescue BuildError => e
        msg = e.message.to_s.lines.last(5).join
        odie "vp #{args.first} failed (#{e.class}):\n#{msg}" if attempt == max_attempts
        sleep 10
      end
    end

    vp_with_retry.call "create", "vite:application", "--no-interactive", "--directory", "test-app"
    assert_path_exists testpath/"test-app/package.json"

    # OHOS: the scaffolded app resolves vite-plus from the npm registry,
    # which ships no openharmony bindings. Wire it the same way an end user
    # would — pnpm-workspace override to the @ohos-npm-ports port (loader
    # patched, prebuilt ohos binding in-package), packageExtensions to give
    # the port's registry vite-plus-core dependency the @rolldown
    # openharmony binding its bundled loader requires (published natively;
    # core bundles the loader but never declares the platform package),
    # ohos-signpost to sign the bindings pnpm fetched unsigned (the port's
    # own binding ships signed, registry ones do not), and drop the
    # scaffold's `prepare: vp config` hook, which runs before install can
    # fetch bindings. The scaffold's workspace file already has an
    # overrides section (vite: catalog:), so merge into it.
    pkg_json = testpath/"test-app/package.json"
    manifest = JSON.parse(pkg_json.read)
    manifest["scripts"].delete("prepare")
    manifest["devDependencies"] ||= {}
    manifest["devDependencies"]["ohos-signpost"] = "^1.0.2"
    manifest["scripts"]["postinstall"] = "ohos-signpost"
    File.write(pkg_json, JSON.pretty_generate(manifest) << "\n")

    workspace = testpath/"test-app/pnpm-workspace.yaml"
    ws = YAML.safe_load(workspace.read)
    ws["overrides"] = {
      "vite-plus" => "npm:@ohos-npm-ports/vite-plus@0.2.8-1",
    }.merge(ws["overrides"] || {})
    ws["packageExtensions"] = {
      "@voidzero-dev/vite-plus-core@0.2.8" => {
        "optionalDependencies" => { "@rolldown/binding-openharmony-arm64" => "1.2.2" },
      },
    }.merge(ws["packageExtensions"] || {})
    File.write(workspace, YAML.dump(ws))

    cd testpath/"test-app" do
      vp_with_retry.call "install"
      output = shell_output("#{bin}/vp fmt")
      assert_match "Finished", output
    end
  end
end
