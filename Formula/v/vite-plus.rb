class VitePlus < Formula
  require "json"

  desc "Unified toolchain and entry point for web development"
  homepage "https://viteplus.dev"
  url "https://github.com/voidzero-dev/vite-plus/archive/refs/tags/v0.2.8.tar.gz"
  sha256 "c07ae8f828039fae32b791abcfc8f1d1b769024a2ae5c04bdc2946e8318615f4"
  license "MIT"
  head "https://github.com/voidzero-dev/vite-plus.git", branch: "main"

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
    # builds (same libc/ABI family, cf. opentui-core) under the openharmony
    # package name. Covers every napi package in the store declaring a
    # *-linux-arm64-musl optional dependency (yuku-*, @ast-grep/napi, ...);
    # pure-JS packages declare none and are skipped.
    system "pnpm", "install"
    sign_tool = "#{formula_opt_prefix("ohos-sdk")}/bin/binary-sign-tool"
    tars_cache = HOMEBREW_CACHE/"vite-plus-musl-napi"
    buildpath.glob("node_modules/.pnpm/*/node_modules/{*,*/*}").each do |pkg_dir|
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
      stage = buildpath/"musl-napi-#{name.tr("/@", "__")}"
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
      # Scoped packages nest one level deeper (@scope/pkg); walk up to the
      # real store node_modules dir.
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

    # Deploy next to the libexec'd vp binary: it resolves its JS entry
    # relative to its own location (<dir>/../node_modules/vite-plus).
    system "pnpm", "--filter=vite-plus", "deploy", "--prod", "--legacy", "--no-optional",
           libexec/"node_modules/vite-plus"
    node_modules = libexec/"node_modules/vite-plus/node_modules"
    rm_r node_modules.glob(".pnpm/*/node_modules/*/prebuilds/{darwin,ios}-x64*")
    rm_r node_modules.glob(".pnpm/fsevents@*/node_modules/fsevents")

    # OHOS: /tmp is read-only and vp's Rust install path creates tempdirs via
    # TMPDIR (defaulting to /tmp) — wrap the real binary in libexec with a
    # cache-backed TMPDIR default, with VP_TMPDIR as the override hatch.
    libexec_bin = libexec/"bin"
    mkdir_p libexec_bin
    odie "cargo install did not produce bin/vp" unless (bin/"vp").exist?
    mv bin/"vp", libexec_bin/"vp"
    (bin/"vp").write <<~SH
      #!/bin/sh
      TMPDIR_DEFAULT="#{HOMEBREW_PREFIX}/var/cache"
      export TMPDIR="${TMPDIR:-$TMPDIR_DEFAULT}"
      export VP_TMPDIR="${VP_TMPDIR:-$TMPDIR}"
      mkdir -p "$TMPDIR" 2>/dev/null
      # Default vp to the system Node.js: its managed-runtime fallback downloads
      # official binaries that OHOS refuses to exec unsigned.
      if [ -n "$HOME" ] && [ ! -f "$HOME/.vite-plus/config.json" ]; then
        mkdir -p "$HOME/.vite-plus" 2>/dev/null &&
          printf '{"shimMode":"system_first"}\\n' > "$HOME/.vite-plus/config.json" 2>/dev/null
      fi
      exec "#{libexec_bin}/vp" "$@"
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

  test do
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

    # vp fmt is intentionally not exercised here: the scaffolded app pulls
    # vite-plus from the npm registry, whose published builds ship no
    # openharmony native binding, so the CLI aborts on load. Upstream would
    # need to publish an openharmony binding first.
  end
end
