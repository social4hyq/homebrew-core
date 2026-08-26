class VitePlus < Formula
  require "json"

  desc "Unified toolchain and entry point for web development"
  homepage "https://viteplus.dev"
  url "https://github.com/voidzero-dev/vite-plus/archive/refs/tags/v0.2.8.tar.gz"
  sha256 "c07ae8f828039fae32b791abcfc8f1d1b769024a2ae5c04bdc2946e8318615f4"
  license "MIT"
  head "https://github.com/voidzero-dev/vite-plus.git", branch: "main"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/vite-plus-v0.2.8-r3"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2091fab5bb77237256f488c80af44ddfa33003aa96a5e40f0dfed4c0fa073211"
  end

  depends_on "cmake" => :build
  depends_on "just" => :build
  depends_on "ohos-sdk" => :build
  depends_on "pnpm@10" => :build
  depends_on "rust" => :build
  # pnpm@11.23 regressed deploy --legacy (pnpm/pnpm#14130: crash on packages
  # without peerDependencies); upstream pins the 10.x line anyway. Build-time
  # work therefore runs under pnpm@10 (prepended onto PATH in install()).
  # Runtime keeps the unversioned pnpm: vp scaffolding shells out to a package
  # manager, and brew test exercises those flows.
  depends_on "node"
  depends_on "pnpm"
  # Upstream pins a nightly toolchain solely for `-Z bindeps` (fspy preload
  # artifact deps). RUSTC_BOOTSTRAP=1 unlocks that flag on harmonybrew's
  # native stable rust below, so no rustup/nightly download is needed.

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

  resource "vite-task" do
    url "https://github.com/voidzero-dev/vite-task.git",
        revision: "5c1d02c750ac21c6f4cf0528062590a145e87fd1"
    version "5c1d02c750ac21c6f4cf0528062590a145e87fd1"
  end

  def install
    resource("rolldown").stage buildpath/"rolldown"
    resource("vite").stage buildpath/"vite"

    # pnpm >= 11.20 verifies the engine binary against the env lockfile when
    # delegating to a packageManager-pinned version; no published @pnpm/exe
    # exists for the openharmony platform. Drop the pins everywhere (vite-plus,
    # vendored rolldown and vite each declare their own) and use system pnpm
    # (same workaround as Alpine packaging).
    Dir.glob(buildpath.glob("**/package.json")).each do |path|
      # Test fixtures may contain non-strict JSON; they never drive pnpm.
      pkg = begin
        JSON.parse(File.read(path))
      rescue JSON::ParserError
        next
      end
      next unless pkg.delete("packageManager")

      File.write(path, JSON.pretty_generate(pkg) << "\n")
    end

    ENV["NPM_CONFIG_MANAGE_PACKAGE_MANAGER_VERSIONS"] = "false"
    ENV["npm_config_manage_package_manager_versions"] = "false"

    # Build-time work runs under pnpm@10 (see depends_on); the unversioned
    # pnpm stays the runtime choice for vp.
    ENV.prepend_path "PATH", formula_opt_bin("pnpm@10")

    # Unlocks `-Z bindeps` (fspy preload artifact deps) on the stable compiler.
    # The repo's rust-toolchain.toml nightly pin is inert here: plain cargo
    # (not a rustup proxy) ignores it.
    ENV["RUSTC_BOOTSTRAP"] = "1"

    # Direct crates.io access stalls on some networks (the local OHOS
    # container); route through rsproxy there. Probe first so fast-network
    # environments (CI runners) keep using crates.io directly.
    unless system "curl", "-fsIL", "--max-time", "8", "-o", File::NULL,
                  "https://index.crates.io/config.json"
      ENV["CARGO_REGISTRIES_CRATES_IO_INDEX"] = "sparse+https://rsproxy.cn/index/"
    end

    # @napi-rs/cli builds the ohos linker/cc/ar paths from this (must point at
    # the SDK's native dir, not the SDK root).
    ENV["OHOS_SDK_NATIVE"] = "#{formula_opt_prefix("ohos-sdk")}/native"

    # Upstream publishes no openharmony napi bindings; reuse linux-arm64-musl
    # builds (same libc/ABI family, cf. opentui-core). Injection must happen
    # TWICE: once right after `pnpm install` (just build's build-node step
    # loads yuku-*/ast-grep bindings at build time), and once after
    # `pnpm deploy` (deploy rebuilds node_modules and drops physically
    # copied modules — r1 shipped without bindings for exactly this reason).
    system "pnpm", "install"

    sign_tool = "#{formula_opt_prefix("ohos-sdk")}/bin/binary-sign-tool"
    tars_cache = HOMEBREW_CACHE/"vite-plus-musl-napi"
    inject_musl_napi = lambda do |store_root|
      store_root.glob(".pnpm/*/node_modules/{*,*/*}").each do |pkg_dir|
        next unless File.directory?(pkg_dir)

        manifest_path = pkg_dir/"package.json"
        next unless manifest_path.exist?

        begin
          manifest = JSON.parse(File.read(manifest_path))
        rescue JSON::ParserError
          next
        end
        name = manifest["name"]
        next if name.nil? || !name.is_a?(String)

        musl_dep = manifest.fetch("optionalDependencies", {}).keys.find do |dep|
          dep.end_with?("-linux-arm64-musl")
        end
        next if musl_dep.nil?

        scope = musl_dep.start_with?("@") ? musl_dep.split("/").first : nil
        musl_base = musl_dep.split("/").last
        ohos_base = musl_base.sub("linux-arm64-musl", "openharmony-arm64")
        ohos_module = scope ? "#{scope}/#{ohos_base}" : ohos_base
        version = manifest.fetch("version")

        tgz = tars_cache/"#{musl_dep.tr("/", "-")}-#{version}.tgz"
        unless tgz.exist?
          tgz.parent.mkpath
          system "curl", "-fSL", "--retry", "5", "-o", tgz,
                 "https://registry.npmmirror.com/#{musl_dep}/-/#{musl_base}-#{version}.tgz"
        end
        stage_name = "#{store_root.to_s.tr("/", "_").delete("^a-zA-Z0-9_@.-")}-#{name.tr("/@", "__")}"
        stage = store_root/stage_name
        rm_r(stage) if stage.exist?
        stage.mkpath
        system "tar", "xzf", tgz, "-C", stage
        node_src = Dir.glob("#{stage}/**/*.node").first
        odie "no .node found in #{tgz}" if node_src.nil?
        node_base = File.basename(node_src)
        # Loader conventions differ across generators: yuku's loader wants a
        # bare "<pkg>.node" file, ast-grep's wants "<bin>.openharmony-arm64.node".
        node_ohos_name = node_base.sub("linux-arm64-musl", "openharmony-arm64")

        # 1) Fabricated module next to the package (module-resolution path):
        #    main points straight at the .node so no JS loader platform check
        #    can interfere.
        node_files = []
        store = pkg_dir.parent
        store = store.parent if name.start_with?("@")
        dest = store/ohos_module
        unless dest.exist?
          dest.mkpath
          cp node_src, dest/node_base
          node_files << (dest/node_base)
          (dest/"package.json").write <<~JSON
            {
              "name": "#{ohos_module}",
              "version": "#{version}",
              "main": "#{node_base}"
            }
          JSON
          if scope
            pkg_leaf = File.basename(name)
            bare = "#{pkg_leaf}.node"
            cp node_src, dest/bare
            node_files << (dest/bare)
          end
        end

        # 2) Files inside the package itself (__dirname-relative fallbacks):
        pkg_leaf = File.basename(name)
        cp node_src, pkg_dir/node_ohos_name
        node_files << (pkg_dir/node_ohos_name)
        cp node_src, pkg_dir/"#{pkg_leaf}.node"
        node_files << (pkg_dir/"#{pkg_leaf}.node")
        if scope
          inner = pkg_dir/scope/ohos_base
          unless inner.exist?
            inner.mkpath
            cp node_src, inner/"#{pkg_leaf}.node"
            node_files << (inner/"#{pkg_leaf}.node")
          end
        end

        # OHOS refuses to dlopen unsigned ELF shared objects; the musl builds
        # ship unsigned.
        node_files.each do |file|
          system sign_tool, "sign", "-selfSign", "1", "-inFile", file, "-outFile", file
        end
      end
    end

    inject_musl_napi.call buildpath/"node_modules"

    # fspy_preload_unix (git dep) compiles as an empty crate on musl, where
    # seccomp alone handles access tracking; extend the exemption to ohos,
    # whose libc lacks the statx/execveat bindings it needs. Patched in via
    # the [patch] block upstream reserves for local vite-task development.
    # Stage vite-task OUTSIDE the workspace dir (persistent cache): upstream's
    # flow keeps it at ../vite-task, and a nested workspace inside the tree
    # derails cargo's workspace-root selection for the patched members.
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

    odie "vite-task root manifest missing" unless (vt_dir/"Cargo.toml").exist?

    system "just", "build"
    system "cargo", "install", *std_cargo_args(path: "crates/vite_global_cli")

    # Deploy to prefix/node_modules/vite-plus, same layout as upstream
    # homebrew-core: the vp binary resolves its JS entry relative to its own
    # location (<dir>/../node_modules/vite-plus).
    system "pnpm", "--filter=vite-plus", "deploy", "--prod", "--legacy", "--no-optional",
           prefix/"node_modules/vite-plus"
    node_modules = prefix/"node_modules/vite-plus/node_modules"
    rm_r node_modules.glob(".pnpm/*/node_modules/*/prebuilds/{darwin,ios}-x64*")
    rm_r node_modules.glob(".pnpm/fsevents@*/node_modules/fsevents")

    # Musl-napi injection, second pass: deploy rebuilt node_modules from
    # scratch, so re-run on the deployed tree (see comment above).
    inject_musl_napi.call node_modules
    rm_r prefix.glob("musl-napi-*")

    # tsgolint (type-aware backend): upstream ships no openharmony binary;
    # the @ohos-npm-ports port does. Embed its signed binary into the
    # deployed oxlint-tsgolint package and teach the loader the
    # openharmony branch, same shape as our registry port.
    tspkg = prefix/"node_modules/vite-plus/node_modules/oxlint-tsgolint"
    if (tspkg/"bin/tsgolint.js").exist?
      tsgo_port = JSON.parse(Utils.safe_popen_read("npm", "view",
        "@ohos-npm-ports/oxlint-tsgolint", "version", "--json"))
      system "curl", "-fSL", "--retry", "5", "-o", "#{tars_cache}/tsgo-port.tgz",
             "https://registry.npmjs.org/@ohos-npm-ports/oxlint-tsgolint/-/oxlint-tsgolint-#{tsgo_port}.tgz"
      stage = prefix/"tsgolint-port"
      rm_r(stage) if stage.exist?
      stage.mkpath
      system "tar", "xzf", "#{tars_cache}/tsgo-port.tgz", "-C", stage

      ohos_dir = tspkg/"@oxlint-tsgolint/openharmony-arm64"
      ohos_dir.mkpath
      cp_r stage/"package/@oxlint-tsgolint/openharmony-arm64/.", ohos_dir
      chmod 0755, ohos_dir/"tsgolint"

      loader_old = <<~JS
        const exePath = require.resolve(
          `@oxlint-tsgolint/${process.platform}-${process.arch}/tsgolint${process.platform === 'win32' ? '.exe' : ''}`,
        );
      JS
      loader_new = <<~JS
        const exePath =
          process.platform === 'openharmony'
            ? require('node:path').join(__dirname, '..', '@oxlint-tsgolint', 'openharmony-arm64', 'tsgolint')
            : require.resolve(
                `@oxlint-tsgolint/${process.platform}-${process.arch}/tsgolint${process.platform === 'win32' ? '.exe' : ''}`,
              );
      JS
      inreplace tspkg/"bin/tsgolint.js", loader_old.chomp, loader_new.chomp
      rm_r(stage)
    end

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
      via TMPDIR (defaulting to /tmp), so set it to a writable directory:

        export TMPDIR=#{HOMEBREW_PREFIX}/var/cache

      vp's managed Node.js runtime fallback downloads official binaries that
      OHOS refuses to exec unsigned; vp defaults to the system Node.js when
      ~/.vite-plus/config.json contains {"shimMode":"system_first"} (written
      automatically on first run if the file does not exist).
    EOS
  end

  test do
    # OHOS: /tmp is read-only and vp's Rust install path creates tempdirs
    # via TMPDIR (defaulting to /tmp). See caveats — end users must set the
    # same variable; the test environment provides it here.
    ENV["TMPDIR"] = testpath/"tmp"
    mkdir_p ENV["TMPDIR"]
    # vp's managed Node.js runtime fallback downloads official glibc binaries
    # that OHOS cannot exec. Point vp at the system Node.js the same way the
    # caveats tell end users to.
    (testpath/".vite-plus").mkpath
    (testpath/".vite-plus/config.json").write <<~JSON
      {"shimMode":"system_first"}
    JSON
    ENV["HOME"] = testpath.to_s

    assert_match version.to_s, shell_output("#{bin}/vp --version")

    # vp create/fmt hit transient exec/FS-settle ENOENTs on OHOS under load;
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

    # The scaffolded app resolves vite-plus from the npm registry, whose
    # published builds ship no openharmony bindings. Wire it to the
    # @ohos-npm-ports ports (oxfmt/rolldown OHOS bindings ship natively from
    # upstream; oxlint's starts at 1.78 while the catalog pins 1.76, but vp
    # fmt does not touch oxlint; tsgolint has no openharmony binary at all
    # and --type-aware needs it). The app carries an ohos-signpost
    # postinstall hook, so pnpm-installed .node files get signed during
    # install (OHOS refuses to dlopen unsigned binaries). The scaffold's
    # workspace file already has an overrides section (vite: catalog:), so
    # merge into it rather than appending a duplicate key.
    pkg_json = testpath/"test-app/package.json"
    manifest = JSON.parse(pkg_json.read)
    manifest["devDependencies"]["ohos-signpost"] = "^1.0.2"
    manifest["scripts"]["postinstall"] = "ohos-signpost"
    # Pathname#write refuses to overwrite files vp create already wrote;
    # use File.write to update them in place.
    File.write(pkg_json, JSON.pretty_generate(manifest) << "\n")

    workspace = testpath/"test-app/pnpm-workspace.yaml"
    ws = YAML.safe_load(workspace.read)
    ws["overrides"] = {
      "vite"            => "catalog:",
      "vite-plus"       => "npm:@ohos-npm-ports/vite-plus@0.2.8-1",
      "oxlint-tsgolint" => "npm:@ohos-npm-ports/oxlint-tsgolint@7.0.2001-1",
    }.merge(ws["overrides"] || {})
    File.write(workspace, YAML.dump(ws))
    vp_with_retry.call "--dir", "test-app", "install"

    # vp fmt loads vite-plus-core's bundled rolldown binding copy from
    # dist/rolldown/shared/ (outside package resolution); the bottle ships
    # a signed copy — plant it in the app's store too.
    bottle_core = Dir.glob(
      "#{HOMEBREW_PREFIX}/Cellar/vite-plus/*/libexec/node_modules/vite-plus/" \
      "node_modules/.pnpm/@voidzero-dev+vite-plus-core@*/node_modules/@voidzero-dev/vite-plus-core",
    ).first
    core_src = File.join(bottle_core, "dist/rolldown/rolldown-binding.openharmony-arm64.node")
    shared_dirs = (testpath/"test-app/node_modules/.pnpm")
                  .glob("**/@voidzero-dev/vite-plus-core/dist/rolldown/shared")
    shared_dirs.each do |dir|
      dst = dir/"rolldown-binding.openharmony-arm64.node"
      next if dst.exist?

      cp core_src, dst
      chmod 0755, dst
    end

    cd testpath/"test-app" do
      output = shell_output("#{bin}/vp fmt")
      assert_match "Finished", output

      # type-aware lint exercises the embedded tsgolint binary end to end.
      (testpath/"test-app/fp.ts").write <<~TS
        const p = new Promise<number>((resolve) => resolve(1));
        async function main() {
          p.then((v) => { console.log(v); });
        }
        main();
      TS
      output = shell_output("#{bin}/vp lint --type-aware fp.ts")
      assert_match "no-floating-promises", output
    end
  end
end
