class VitePlus < Formula
  require "json"
  require "yaml"

  desc "Unified toolchain and entry point for web development"
  homepage "https://viteplus.dev"
  url "https://github.com/voidzero-dev/vite-plus/archive/refs/tags/v0.2.8.tar.gz"
  sha256 "c07ae8f828039fae32b791abcfc8f1d1b769024a2ae5c04bdc2946e8318615f4"
  license "MIT"

  # OHOS: bottle content differs from upstream (musl-napi injection, wrapper).
  revision 1
  head "https://github.com/voidzero-dev/vite-plus.git", branch: "main"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/vite-plus-v0.2.8-r3"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2091fab5bb77237256f488c80af44ddfa33003aa96a5e40f0dfed4c0fa073211"
  end

  depends_on "cmake" => :build
  depends_on "just" => :build
  # OHOS: binary-sign-tool (musl .node signing) + OHOS_SDK_NATIVE toolchain.
  depends_on "ohos-sdk" => :build
  # OHOS: pnpm >= 11.23 regressed `deploy --legacy` (pnpm/pnpm#14130: crash on
  # packages without peerDependencies). Build-time work runs under pnpm@10;
  # the unversioned pnpm stays the runtime choice for vp.
  depends_on "pnpm@10" => :build
  # OHOS: no rustup formula here; stable rust + RUSTC_BOOTSTRAP (see install).
  depends_on "rust" => :build
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

    # --- OHOS build environment -------------------------------------------
    # pnpm >= 11.20 verifies the engine binary against the env lockfile when
    # delegating to a packageManager-pinned version; no published @pnpm/exe
    # exists for openharmony. Drop the pins everywhere (vite-plus, vendored
    # rolldown and vite each declare their own) — same workaround as Alpine.
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
    ENV.prepend_path "PATH", formula_opt_bin("pnpm@10")
    # Unlocks `-Z bindeps` (fspy preload artifact deps) on the stable
    # compiler; the repo's rust-toolchain.toml nightly pin is inert here.
    ENV["RUSTC_BOOTSTRAP"] = "1"
    # Direct crates.io access stalls on some networks; route through rsproxy
    # there. Probe first so fast networks (CI) keep using crates.io directly.
    unless system "curl", "-fsIL", "--max-time", "8", "-o", File::NULL,
                  "https://index.crates.io/config.json"
      ENV["CARGO_REGISTRIES_CRATES_IO_INDEX"] = "sparse+https://rsproxy.cn/index/"
    end
    # @napi-rs/cli builds the ohos linker/cc/ar paths from this (must point
    # at the SDK's native dir, not the SDK root).
    ENV["OHOS_SDK_NATIVE"] = "#{formula_opt_prefix("ohos-sdk")}/native"

    # --- OHOS musl-napi injection -----------------------------------------
    # Most napi packages publish no openharmony bindings; reuse their
    # linux-arm64-musl builds (same libc/ABI family, cf. opentui-core).
    # Injection happens TWICE: right after `pnpm install` (just build's
    # build-node step loads yuku-*/ast-grep bindings at build time) and after
    # `pnpm deploy` (deploy rebuilds node_modules and drops physically copied
    # modules).
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

        # OHOS refuses to dlopen unsigned ELF shared objects; the musl
        # builds ship unsigned.
        node_files.each do |file|
          system sign_tool, "sign", "-selfSign", "1", "-inFile", file, "-outFile", file
        end
      end
    end
    inject_musl_napi.call buildpath/"node_modules"

    # --- OHOS vite-task patch ---------------------------------------------
    # fspy_preload_unix (git dep) compiles as an empty crate on musl, where
    # seccomp alone handles access tracking; extend the exemption to ohos,
    # whose libc lacks the statx/execveat bindings it needs. Staged OUTSIDE
    # the workspace dir (persistent cache): a nested workspace inside the
    # tree derails cargo's workspace-root selection.
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

    # OHOS: second injection pass on the deployed tree (see above).
    inject_musl_napi.call node_modules
    rm_r prefix.glob("musl-napi-*")

    # --- OHOS wrapper ------------------------------------------------------
    # Hand-rolled rather than write_env_script: the default-if-unset TMPDIR
    # export and the first-run config seeding below cannot be expressed with
    # write_env_script's unconditional exports. Two load-bearing behaviors,
    # verified on device: (1) vp's Rust install path creates tempdirs via
    # TMPDIR, which defaults to the read-only /tmp; (2) with no
    # ~/.vite-plus/config.json vp's default ShimMode is "managed" — it
    # downloads official glibc Node.js binaries that OHOS refuses to exec
    # (raw binary + fresh HOME fails with EACCES). The real binary sits
    # exactly one level below prefix so <dir>/../node_modules still resolves
    # to the prefix/node_modules deploy target above.
    odie "cargo install did not produce bin/vp" unless (bin/"vp").exist?
    mv bin/"vp", libexec/"vp"
    (bin/"vp").write <<~SH
      #!/bin/sh
      TMPDIR_DEFAULT="#{HOMEBREW_PREFIX}/var/cache"
      export TMPDIR="${TMPDIR:-$TMPDIR_DEFAULT}"
      mkdir -p "$TMPDIR" 2>/dev/null
      # Seed system_first so the managed-runtime downloader is never the
      # default path on OHOS; delete ~/.vite-plus/config.json to opt out.
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
    # OHOS: /tmp is read-only and vp's Rust install path creates tempdirs
    # via TMPDIR (defaulting to /tmp). bin/vp wraps the real binary with a
    # writable-TMPDIR default; the test still sets it explicitly so temp
    # files land inside testpath. HOME is pointed at testpath so the
    # wrapper's first-run seeding of shimMode=system_first (managed-Node
    # downloads are glibc builds OHOS cannot exec) lands here.
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
    # which ships no openharmony bindings, so `vp fmt` in the app aborts on
    # load. Wire the app the same way an end user would: pnpm-workspace
    # override to the @ohos-npm-ports port (which ships pre-signed
    # bindings), ohos-signpost to sign anything pnpm pulled unsigned, and
    # drop the scaffold's `prepare: vp config` hook — it runs during install
    # before the rolldown binding plant below and dies on the missing
    # openharmony binding. The scaffold's workspace file already has an
    # overrides section (vite: catalog:), so merge into it rather than
    # appending a duplicate key.
    pkg_json = testpath/"test-app/package.json"
    manifest = JSON.parse(pkg_json.read)
    manifest["devDependencies"]["ohos-signpost"] = "^1.0.2"
    manifest["scripts"]["postinstall"] = "ohos-signpost"
    manifest["scripts"].delete("prepare")
    # Pathname#write refuses to overwrite files vp create already wrote;
    # use File.write to update them in place.
    File.write(pkg_json, JSON.pretty_generate(manifest) << "\n")

    workspace = testpath/"test-app/pnpm-workspace.yaml"
    ws = YAML.safe_load(workspace.read)
    ws["overrides"] = {
      "vite-plus" => "npm:@ohos-npm-ports/vite-plus@0.2.8-1",
    }.merge(ws["overrides"] || {})
    File.write(workspace, YAML.dump(ws))

    # vp 0.2.8 has no global --dir flag (clap rejects it), so run install
    # from inside the app directory.
    cd testpath/"test-app" do
      vp_with_retry.call "install"
    end

    # OHOS: vp fmt loads vite-plus-core's bundled rolldown binding copy from
    # dist/rolldown/shared/ (outside package resolution); the bottle ships a
    # signed copy — plant it in the app's store too.
    bottle_core = Dir.glob(
      "#{HOMEBREW_PREFIX}/Cellar/vite-plus/*/node_modules/vite-plus/" \
      "node_modules/.pnpm/@voidzero-dev+vite-plus-core@*/node_modules/@voidzero-dev/vite-plus-core",
    ).first
    core_src = File.join(bottle_core, "dist/rolldown/rolldown-binding.openharmony-arm64.node")
    (testpath/"test-app/node_modules/.pnpm")
      .glob("**/@voidzero-dev/vite-plus-core/dist/rolldown/shared").each do |dir|
      dst = dir/"rolldown-binding.openharmony-arm64.node"
      next if dst.exist?

      cp core_src, dst
      chmod 0755, dst
    end

    cd testpath/"test-app" do
      output = shell_output("#{bin}/vp fmt")
      assert_match "Finished", output
    end
  end
end
