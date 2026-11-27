class ZcodeDesktop < Formula
  desc "Desktop shell for the ZCode agent (Electron window on a local zcode --web)"
  homepage "https://zcode.z.ai"
  # Same upstream pin as `zcode`: the shell only provides the window, the
  # workbench comes from the installed CLI.
  url "https://github.com/zai-org/ZCode.git",
      revision: "a4b4445141eb7d3b3e99eada9292775383bfc44e"
  version "4.0.0"
  # Tap-authored shell scripts (MIT) on the CPF-Electron runtime (mixed
  # MIT/BSD/LGPL).
  license :cannot_represent
  revision 1

  livecheck do
    url "https://raw.githubusercontent.com/zai-org/ZCode/main/package.json"
    strategy :json do |json|
      json["version"]
    end
  end

  depends_on "bun"
  depends_on "curl"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"
  depends_on "zcode"
  depends_on "zip"

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/_shared/waiting-page/render-waiting.cjs
    Resources/_shared/waiting-page/waiting.html.in
    Resources/zcode-desktop/app/config.json
    Resources/zcode-desktop/app/lifecycle.cjs
    Resources/zcode-desktop/app/main.cjs
    Resources/zcode-desktop/app/package.json
    Resources/zcode-desktop/app/server-auth.cjs
    Resources/zcode-desktop/app/tray.cjs
    Resources/zcode-desktop/app/waiting.json
    Resources/zcode-desktop/assets/icon.png
    Resources/zcode-desktop/assets/tray-icon.png
    Resources/zcode-desktop/tests/close-handler.test.cjs
    Resources/zcode-desktop/tests/lifecycle.test.cjs
    Resources/zcode-desktop/tests/tray.test.cjs
  ].freeze

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/zcode-desktop"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    %w[main.cjs lifecycle.cjs server-auth.cjs tray.cjs package.json config.json].each do |name|
      cp res/"app"/name, app/name
    end
    system "node", tap_root/"Resources/_shared/waiting-page/render-waiting.cjs",
           tap_root/"Resources/_shared/waiting-page/waiting.html.in",
           res/"app/waiting.json", app/"waiting.html"

    cp res/"assets/icon.png", app/"app-icon.png"
    cp res/"assets/tray-icon.png", app/"tray-icon.png"

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.zcodedesktop"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp res/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    # Locale overrides would otherwise keep the Electron launcher label.
    (shell.glob("AppScope/resources/*/element/string.json") +
     shell.glob("electron/src/main/resources/*/element/string.json")).each do |file|
      strings = JSON.parse(file.read)
      strings.fetch("string").each do |entry|
        case entry["name"]
        when "app_name", "EntryAbility_label" then entry["value"] = "ZCode"
        end
      end
      rm file
      file.write JSON.pretty_generate(strings) + "\n"
    end

    # Remove template signing settings and select the shared toolchain's SDK;
    # this profile is strict JSON.
    profile = JSON.parse((shell/"build-profile.json5").read)
    profile.fetch("app").fetch("products").each do |product|
      product.delete("signingConfig")
      product["compatibleSdkVersion"] = "6.0.0(20)"
    end
    profile.fetch("app").delete("signingConfigs")
    profile_file = shell/"build-profile.json5"
    rm profile_file
    profile_file.write JSON.pretty_generate(profile) + "\n"
    inreplace shell/"electron/src/main/module.json5", '"mainElement": "EntryAbility",',
              '"mainElement": "EntryAbility", "extractNativeLibs": true,'

    # The shell only talks to the host service over loopback; restricted
    # permissions go into the ACL variant (module-acl.json).
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\r?\n    \],/m,
              <<~JSON5.chomp
                "requestPermissions": [
                      { "name": "ohos.permission.INTERNET" },
                      { "name": "ohos.permission.GET_NETWORK_INFO" },
                      { "name": "ohos.permission.MICROPHONE", "reason": "$string:microphone", "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" } }
                    ],
              JSON5

    # windowStageClose hides the ability and returns true, which tells the system
    # not to close the window, so the window goes to the tray. Returning false let
    # the system close it right after the hide: the ability's session was destroyed
    # and the whole app was killed and relaunched. The tray quit calls app.exit()
    # to bypass this handler.
    close_handler = [
      "    super.onWindowStageCreate(windowStage);",
      "    try {",
      "      windowStage.on('windowStageClose', () => {",
      "        if (CheckEmptyUtils.isEmpty(this.xcomponentId)) {",
      "          return false;",
      "        }",
      "        const widgetId = Number(this.xcomponentId.substring(ConfigData.WINDOW_PREFIX.length));",
      "        Inject.getOrCreate(AppWindowAdapter).hideWindow(widgetId);",
      "        return true;",
      "      });",
      "    } catch (exception) {",
      "      LogUtil.error(TAG, 'Failed to register window close handler: ' + JSON.stringify(exception));",
      "    }",
      "",
    ].join("\n")
    inreplace shell/"web_engine/src/main/ets/ability/WebAbility.ets",
              "    super.onWindowStageCreate(windowStage);\n", close_handler

    # The proprietary CLT is supplied by the CI image, not distributed by the tap.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "#{name} builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['#{name}']"
    end

    # ohos_packing_tool needs SDK libraries outside brew's sanitized search path.
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    # An oversized RLIMIT_NOFILE breaks the musl FD table in hvigor.
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd shell do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    libexec.install shell/"electron/build/default/outputs/default/electron-default-unsigned.hap" =>
                    "zcode-desktop-unsigned.hap"

    # ACL variant: CUSTOM_SANDBOX and READ_WRITE_USER_FILE let the shell run the
    # host zcode CLI on launch; the kernel ACLs keep WebAssembly (previews, diff
    # worker) and READ_PASTEBOARD makes paste work.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"zcode-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION
       ohos.permission.READ_PASTEBOARD].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    # Register zcode://<host>/callback so the browser OAuth handoff opens the
    # shell; the web client finishes the login through the server poll.
    entry = module_json.fetch("module").fetch("abilities").find { |ability| ability["name"] == "EntryAbility" }
    skills = entry["skills"] ||= []
    unless skills.any? { |skill| Array(skill["uris"]).any? { |uri| uri["scheme"] == "zcode" } }
      skills << {
        "actions" => ["ohos.want.action.viewData"],
        "uris"    => [{ "scheme" => "zcode" }],
      }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # The HAP is delivered through app.json; deployment is an explicit
    # `ohos-app install zcode-desktop`. The upstream CLI stays independent.
    # Descriptor is written at build time with the real HAP digest and version.
    (pkgshare/"ohos").mkpath
    hap = libexec/"zcode-desktop-unsigned.hap"
    hap_sha = Digest::SHA256.file(hap).hexdigest
    version_code = 1 # The HAP has no versionCode field; app.json is authoritative.
    descriptor = {
      "schema_version" => 1,
      "id"             => "social4hyq/core/zcode-desktop",
      "artifact"       => {
        "format"       => "hap",
        "path"         => "../../libexec/zcode-desktop-unsigned.hap",
        "sha256"       => hap_sha,
        "api"          => 12,
        "abis"         => ["arm64-v8a"],
        "bundle_id"    => "com.social4hyq.zcodedesktop",
        "version_name" => version.to_s,
        "version_code" => version_code,
      },
      "launch"         => { "module" => "electron", "ability" => "EntryAbility" },
      "variants"       => {
        "default"     => "acl",
        "definitions" => {
          "basic" => {},
          "acl"   => { "module_overlay" => "module-acl.json",
                       "sha256"         => Digest::SHA256.file(pkgshare/"module-acl.json").hexdigest },
        },
      },
    }
    (pkgshare/"ohos/app.json").write JSON.pretty_generate(descriptor) + "\n"
  end

  test do
    # Only the HAP and descriptor are delivered; no app-level install command.
    refute_path_exists bin/"zcode-app"

    # Descriptor schema, id, digest and variants must match the HAP.
    descriptor = JSON.parse((pkgshare/"ohos/app.json").read)
    assert_equal 1, descriptor["schema_version"]
    assert_equal "social4hyq/core/zcode-desktop", descriptor["id"]
    hap = libexec/"zcode-desktop-unsigned.hap"
    assert_equal Digest::SHA256.file(hap).hexdigest, descriptor.dig("artifact", "sha256")
    assert_equal "com.social4hyq.zcodedesktop", descriptor.dig("artifact", "bundle_id")
    assert_equal "acl", descriptor.dig("variants", "default")
    assert_equal Digest::SHA256.file(pkgshare/"module-acl.json").hexdigest,
                 descriptor.dig("variants", "definitions", "acl", "sha256")

    listing = shell_output("unzip -l #{hap}")
    %w[
      libs/arm64-v8a/libelectron.so
      resources/resfile/resources/app/lifecycle.cjs
      resources/resfile/resources/app/server-auth.cjs
    ].each { |entry| assert_match entry, listing }
    assert_match "onQuitRequest", shell_output("unzip -p #{hap} resources/resfile/resources/app/tray.cjs")
    waiting_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/waiting.html")
    assert_match "ohos-app install zcode-desktop", waiting_source
    refute_match "{{", waiting_source
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_equal 0, placeholder.fetch("port")
    permissions = JSON.parse(shell_output("unzip -p #{hap} module.json"))
                      .fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.MICROPHONE], permissions.sort
    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_requested = acl.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO
                    ohos.permission.INTERNET ohos.permission.MICROPHONE ohos.permission.READ_PASTEBOARD
                    ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_requested.sort

    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    system "node", "--check", tap_root/"Resources/zcode-desktop/app/main.cjs"
    system "node", "--test", tap_root/"Resources/zcode-desktop/tests/lifecycle.test.cjs"
    system "node", "--test", tap_root/"Resources/zcode-desktop/tests/tray.test.cjs"
    system "node", "--test", tap_root/"Resources/zcode-desktop/tests/close-handler.test.cjs"
    system "unzip", "-tq", hap
  end
end
