class DeepseekHarnessDesktop < Formula
  desc "Agent desktop shell with a host-side runtime bridge for OpenHarmony"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://github.com/social4hyq/homebrew-core/releases/download/deepseek-harness-desktop-v0.2.2-rc.3/dsh-desktop-shell-0.2.2-rc.3-88258f42.tar.gz"
  sha256 "88258f42185620890d067cce6b4eb48b759138b4370d5f76388700e2ad22b480"
  license "MIT"

  livecheck do
    skip "Tap-hosted payload, versioned with the formula"
  end

  depends_on "hap-installer"
  depends_on "ripgrep"
  depends_on "zip"

  # Host-side dsh runtime tree: desktop-host plus its full production closure,
  # built from the pinned upstream commit with the OHOS patch set (koffi and
  # node-addon-require-builtin from source, sharp wasm32 fallback, signed
  # .node files, payload Node 24.22.3). See ohos-dsh-desktop/patches.
  resource "runtime" do
    url "https://github.com/social4hyq/homebrew-core/releases/download/deepseek-harness-desktop-v0.2.2-rc.3/dsh-desktop-runtime-0.2.2-rc.3.tar.gz"
    sha256 "3ed036a5ca5babfc22c2c0c42350dee97eb3d5cd0eea28605264cbfcd6fafd1f"
  end

  # openharmony-sig/electron PC(2in1) prebuilt (CodeHub mirror hosted on this
  # tap's release; redistribution assumed by the tap owner, see ohos-multica).
  resource "electron-ohos" do
    url "https://github.com/social4hyq/homebrew-core/releases/download/electron-ohos-v34.9.0-20261030.1/v34.9.0-20261030.1-release.zip"
    sha256 "599e97b3d8b1e5071a2387496104b443e58079a5f5c165b0114e65ffc601df3a"
  end

  def install
    patches = Pathname(__dir__)/"Patches/deepseek-harness-desktop"

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath/"electron-prebuilt"
    system "tar", "-xzf", buildpath/"electron-prebuilt/libelectron_132.tar.gz",
           "-C", buildpath/"electron-prebuilt"
    shell = buildpath/"electron-prebuilt/libelectron/ohos_hap"

    # Homebrew strips the archive's single top-level directory on unpack, so
    # the payload files sit directly in buildpath; tolerate both layouts.
    payload = (buildpath/"app").directory? ? buildpath/"app" : buildpath

    # Branding: upstream icon + product name.
    icon = payload/"icon.png"
    odie "desktop payload carries no icon.png" unless icon.exist?
    %w[app_icon.png startIcon.png].each { |name| cp icon, shell/"AppScope/resources/base/media"/name }
    label_keys = %w[EntryAbility_label StatusBarEntryAbility_label]
    %w[base en_US zh_CN].each do |locale|
      path = shell/"electron/src/main/resources"/locale/"element/string.json"
      manifest = JSON.parse(path.read)
      manifest["string"].each do |entry|
        entry["value"] = "DeepSeek Harness" if label_keys.include?(entry["name"])
      end
      path.write JSON.pretty_generate(manifest)
    end
    app_scope = shell/"AppScope/resources/base/element/string.json"
    scope = JSON.parse(app_scope.read)
    scope["string"].each { |entry| entry["value"] = "DeepSeek Harness" if entry["name"] == "app_name" }
    app_scope.write JSON.pretty_generate(scope)

    # Prebuilt shell payload (Electron main bundle, renderer dist, dependency
    # closure) replaces the shell project's app resources.
    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    %w[lib dsh node_modules package.json icon.png].each { |name| cp_r payload/name, app/name }

    clt = Pathname.new("/opt/electron-ohos-clt")
    odie "deepseek-harness-desktop builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES" unless
      (clt/"hvigor/bin/hvigorw.js").exist?

    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd shell do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    # Host-side runtime tree (dsh + primary-runtime + launchers), prebuilt.
    resource("runtime").stage do
      (libexec/"runtime").install Dir["runtime/*"]
    end
    libexec.install patches/"dsh-desktop-bridge.mjs"
    (libexec/"bridge-wrapper.sh").write((patches/"bridge-wrapper.sh").read)
    chmod 0755, libexec/"bridge-wrapper.sh"
    (bin/"dsh-desktop-bridge").write_env_script libexec/"bridge-wrapper.sh",
      DSH_DESKTOP_BRIDGE_JS:       libexec/"dsh-desktop-bridge.mjs",
      DSH_BRIDGE_NODE:             libexec/"runtime/primary-runtime/dependencies/node/bin/node",
      DSH_DESKTOP_RUNTIME_DIR:     libexec/"runtime/dsh",
      DSH_DESKTOP_PRIMARY_RUNTIME: libexec/"runtime/primary-runtime"
    (pkgshare/"install-desktop.sh").write((patches/"install-desktop.sh").read)
    chmod 0755, pkgshare/"install-desktop.sh"
    (bin/"dsh-install-desktop").write_env_script pkgshare/"install-desktop.sh",
      DSH_DESKTOP_UNSIGNED_HAP: libexec/"dsh-desktop-unsigned.hap"
    libexec.install shell/"electron/build/default/outputs/default/electron-default-unsigned.hap" =>
                     "dsh-desktop-unsigned.hap"
  end

  def caveats
    <<~EOS
      The desktop HAP is unsigned in the bottle: #{opt_libexec}/dsh-desktop-unsigned.hap
      Connect and unlock the device, then run:

        dsh-desktop-bridge          # host-side runtime bridge (also: add to ~/.shellrc)
        dsh-install-desktop         # sign + install + launch through hap-installer

      Signing material stays under your home directory; it is not in the bottle.
      Upgrades go through Harmonybrew (`brew upgrade deepseek-harness-desktop`).
    EOS
  end

  test do
    assert_path_exists libexec/"runtime/dsh/desktop-runtime.json"
    assert_path_exists libexec/"runtime/primary-runtime/dependencies/node/bin/node"
    assert_path_exists libexec/"dsh-desktop-bridge.mjs"
    assert_path_exists libexec/"dsh-desktop-unsigned.hap"
    descriptor = JSON.parse((libexec/"runtime/dsh/desktop-runtime.json").read)
    assert_equal "openharmony", descriptor.fetch("platform")
    assert_equal version.to_s, descriptor.fetch("release").fetch("version")
    listing = shell_output("unzip -l #{libexec}/dsh-desktop-unsigned.hap")
    assert_match "module.json", listing
    assert_match "resources/resfile/resources/app/lib/main.js", listing
    assert_match "resources/resfile/resources/app/dsh/node_modules/@deepseek-ai/dsh-web-frontend/dist", listing
    package_json = "resources/resfile/resources/app/package.json"
    package = JSON.parse(shell_output("unzip -p #{libexec}/dsh-desktop-unsigned.hap #{package_json}"))
    assert_equal version.to_s, package.fetch("version")
  end
end
