class DeepseekHarnessDesktop < Formula
  desc "Agent desktop shell with a host-side runtime bridge for OpenHarmony"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://atomgit.com/social4hyq/homebrew-core/releases/download/deepseek-harness-desktop-v0.2.2-rc.3/dsh-desktop-shell-0.2.2-rc.3-88258f42.tar.gz"
  sha256 "88258f42185620890d067cce6b4eb48b759138b4370d5f76388700e2ad22b480"
  license :cannot_represent # MIT payload; bundles Electron (BSD-style) and other third-party components

  livecheck do
    skip "Tap-hosted payload, versioned with the formula"
  end

  depends_on "hap-installer"
  depends_on "ripgrep"

  # Payloads are hosted on atomgit (the same CDN the bottles use); GitHub
  # release assets stall for minutes through the runner proxy at this size.
  # Host-side dsh runtime tree: desktop-host plus its full production closure,
  # built from the pinned upstream commit with the OHOS patch set (koffi and
  # node-addon-require-builtin from source, sharp wasm32 fallback, signed
  # .node files, payload Node 24.22.3). See ohos-dsh-desktop/patches.
  resource "runtime" do
    url "https://atomgit.com/social4hyq/homebrew-core/releases/download/deepseek-harness-desktop-v0.2.2-rc.3/dsh-desktop-runtime-0.2.2-rc.3.tar.gz"
    sha256 "3ed036a5ca5babfc22c2c0c42350dee97eb3d5cd0eea28605264cbfcd6fafd1f"
  end

  # openharmony-sig/electron PC(2in1) prebuilt (CodeHub mirror hosted on this
  # tap's release; redistribution assumed by the tap owner, see ohos-multica).
  resource "electron-ohos" do
    url "https://github.com/social4hyq/homebrew-core/releases/download/electron-ohos-v34.9.0-20261030.1/v34.9.0-20261030.1-release.zip"
    sha256 "599e97b3d8b1e5071a2387496104b443e58079a5f5c165b0114e65ffc601df3a"
  end

  def install
    # __dir__ 是 Formula/d/；Patches 在 tap 根。MUST use the file ancestry here.
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    patches = tap_root/"Patches/deepseek-harness-desktop"

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
    # Own bundle id: the shared template id collides with every other HAP built
    # from the same electron-ohos shell project.
    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                            '"bundleName": "com.social4hyq.deepseekharness"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    module_json = shell/"web_engine/src/main/module.json5"
    if module_json.exist? && module_json.read.include?("com.huawei.ohos_electron")
      inreplace module_json, '"name": "com.huawei.ohos_electron"',
                '"name": "com.social4hyq.deepseekharness"'
    end
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
      # Bounded so a stalled proxy surfaces at the right step instead of
      # silently eating the job budget.
      system "timeout", "900", "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "timeout", "1800", "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    # Host-side runtime tree (dsh + primary-runtime + launchers), prebuilt.
    resource("runtime").stage do
      # Homebrew strips a tarball's single top-level directory; tolerate both.
      root = Pathname("runtime").directory? ? Pathname("runtime") : Pathname(".")
      %w[dsh/desktop-runtime.json primary-runtime/dependencies/node/bin/node].each do |probe|
        raise "runtime payload is missing #{probe}" unless (root/probe).exist?
      end
      (libexec/"runtime").install Dir[root/"*"]
    end
    libexec.install patches/"dsh-desktop-bridge.mjs"
    (libexec/"dsh-desktop.sh").write((patches/"dsh-desktop.sh").read)
    chmod 0755, libexec/"dsh-desktop.sh"
    # opt_ paths: a bridge started from an old keg must resolve the currently
    # linked version after `brew upgrade`; start replaces a stale process.
    (bin/"deepseek-harness-desktop").write_env_script opt_libexec/"dsh-desktop.sh",
      DSH_DESKTOP_BRIDGE_JS:       opt_libexec/"dsh-desktop-bridge.mjs",
      DSH_BRIDGE_NODE:             opt_libexec/"runtime/primary-runtime/dependencies/node/bin/node",
      DSH_DESKTOP_RUNTIME_DIR:     opt_libexec/"runtime/dsh",
      DSH_DESKTOP_PRIMARY_RUNTIME: opt_libexec/"runtime/primary-runtime",
      DSH_DESKTOP_UNSIGNED_HAP:    opt_libexec/"dsh-desktop-unsigned.hap"
    libexec.install shell/"electron/build/default/outputs/default/electron-default-unsigned.hap" =>
                     "dsh-desktop-unsigned.hap"
  end

  def caveats
    <<~EOS
      The desktop HAP is unsigned in the bottle: #{opt_libexec}/dsh-desktop-unsigned.hap
      Connect and unlock the device, then run:

        #{opt_bin}/deepseek-harness-desktop install   # sign + install + launch
        #{opt_bin}/deepseek-harness-desktop start     # host-side runtime bridge

      Put the absolute path in your shell startup file (bin/ is often not on
      PATH yet when those files run, and a bare command fails silently):

        "$HOME/.harmonybrew/bin/deepseek-harness-desktop" start --bridge-only


      Signing material stays under your home directory; it is not in the bottle.
      Note: the bridge listens on 127.0.0.1:3090 without its own authentication;
      any local process running as this user can start or drive a Harness Host.
      That is the same privilege boundary as running `dsh` directly.
      Upgrades go through Harmonybrew (`brew upgrade deepseek-harness-desktop`).
    EOS
  end

  test do
    assert_path_exists libexec/"runtime/dsh/desktop-runtime.json"
    node = libexec/"runtime/primary-runtime/dependencies/node/bin/node"
    assert_path_exists node
    assert_match "v24.", shell_output("#{node} --version")
    assert_path_exists libexec/"dsh-desktop-bridge.mjs"
    assert_path_exists libexec/"dsh-desktop-unsigned.hap"
    descriptor = JSON.parse((libexec/"runtime/dsh/desktop-runtime.json").read)
    assert_equal "openharmony", descriptor.fetch("platform")
    assert_equal version.to_s, descriptor.fetch("release").fetch("version")
    hap = libexec/"dsh-desktop-unsigned.hap"
    system "unzip", "-tq", hap
    listing = shell_output("unzip -l #{hap}")
    assert_match "module.json", listing
    assert_match "resources/resfile/resources/app/lib/main.js", listing
    assert_match "resources/resfile/resources/app/dsh/node_modules/@deepseek-ai/dsh-web-frontend/dist", listing
    profile = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.deepseekharness", profile.fetch("app").fetch("bundleName")
    package_json = "resources/resfile/resources/app/package.json"
    package = JSON.parse(shell_output("unzip -p #{hap} #{package_json}"))
    assert_equal version.to_s, package.fetch("version")

    # The CLI wrapper must use the stable opt paths.
    wrapper = (bin/"deepseek-harness-desktop").read
    assert_match "opt/deepseek-harness-desktop/libexec/dsh-desktop.sh", wrapper
    assert_match "opt/deepseek-harness-desktop/libexec/runtime/primary-runtime", wrapper

    # install must hand the generated HAP and matching identifiers to hap-installer.
    fake_bin = testpath/"bin"
    fake_bin.mkpath
    args_file = testpath/"hap-installer-args"
    fake = fake_bin/"hap-installer"
    fake.write <<~SH
      #!/bin/sh
      printf '%s\n' "$@" > #{args_file}
    SH
    chmod 0755, fake
    ENV.prepend_path "PATH", fake_bin
    ENV["DSH_BRIDGE_STATE_DIR"] = testpath/"state"
    system bin/"deepseek-harness-desktop", "install"
    args = args_file.read.lines(chomp: true)
    assert_equal ["--hap", hap.to_s, "--bundle-id", "com.social4hyq.deepseekharness",
                  "--app-name", "DeepSeekHarnessSigning", "--module", "electron",
                  "--ability", "EntryAbility"], args

    # status works without a running bridge and reports the payload version.
    status = shell_output("#{bin}/deepseek-harness-desktop status")
    assert_match(/bridge: (not running|running)/, status)
    assert_match "runtime: #{version}", status
  end
end
