class DeepseekHarnessDesktop < Formula
  desc "Desktop shell for the DeepSeek Harness agent (Electron window on local dsh web)"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://github.com/deepseek-ai/deepseek-harness/archive/refs/tags/dsh-v0.2.3-alpha.2.tar.gz"
  sha256 "e3ae29a992f19f85294806e95b1bc0fef750ca23ce06b2d88944b4bc2a2b3064"
  license :cannot_represent
  revision 3

  livecheck do
    url "https://github.com/deepseek-ai/deepseek-harness.git"
    regex(/^dsh-v(\d+\.\d+\.\d+(?:-(?:alpha|rc)\.\d+)?)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/deepseek-harness-desktop-v0.2.3-alpha.2-r7"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "241bfa5cbe2c643aebe7d753264b42a7e9a1bd3cc2a54cb678b0767ed058c38d"
  end

  depends_on "ohos-hap-clt" => :build
  depends_on "coreutils"
  depends_on "curl"
  depends_on "deepseek-harness"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"
  depends_on "util-linux"
  depends_on "zip"

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  # Publicly mirrored official CLT replaces the private electron-ohos-ci image.
  resource "command-line-tools" do
    url "https://s3.oheco.org/command-line-tools/26.0.0.201/commandline-tools-harmonyos-26.0.0.201.tar.gz"
    sha256 "60929c00ae486cc038ea48145497ad34dbd4ac6a25c3f2fa895ce74afb4607f5"
  end

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/_shared/waiting-page/render-waiting.cjs
    Resources/_shared/waiting-page/waiting.html.in
    Resources/deepseek-harness-desktop/app/config.json
    Resources/deepseek-harness-desktop/app/main.cjs
    Resources/deepseek-harness-desktop/app/package.json
    Resources/deepseek-harness-desktop/app/proxy-preload.cjs
    Resources/deepseek-harness-desktop/app/proxy.cjs
    Resources/deepseek-harness-desktop/app/startup.cjs
    Resources/deepseek-harness-desktop/app/tray.cjs
    Resources/deepseek-harness-desktop/app/waiting.json
    Resources/deepseek-harness-desktop/assets/icon.png
    Resources/deepseek-harness-desktop/assets/tray-icon.png
    Resources/deepseek-harness-desktop/tests/close-handler.test.cjs
    Resources/deepseek-harness-desktop/tests/test-proxy.cjs
    Resources/deepseek-harness-desktop/tests/test-server-detach.rb
    Resources/deepseek-harness-desktop/tests/test-startup.cjs
  ].freeze

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/deepseek-harness-desktop"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    cp res/"app/main.cjs", app
    cp res/"app/proxy-preload.cjs", app
    cp res/"app/proxy.cjs", app
    cp res/"app/startup.cjs", app
    cp res/"app/tray.cjs", app
    cp res/"app/package.json", app
    cp res/"app/config.json", app
    system "node", tap_root/"Resources/_shared/waiting-page/render-waiting.cjs",
           tap_root/"Resources/_shared/waiting-page/waiting.html.in",
           res/"app/waiting.json", app/"waiting.html"

    cp res/"assets/icon.png", app/"app-icon.png"
    cp res/"assets/tray-icon.png", app/"tray-icon.png"

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.deepseekharness"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp res/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    (shell.glob("AppScope/resources/*/element/string.json") +
     shell.glob("electron/src/main/resources/*/element/string.json")).each do |file|
      strings = JSON.parse(file.read)
      strings.fetch("string").each do |entry|
        case entry["name"]
        when "app_name", "EntryAbility_label" then entry["value"] = "DeepSeek Harness"
        end
      end
      File.write(file.to_s, JSON.pretty_generate(strings) + "\n")
    end

    inreplace shell/"build-profile.json5", /[ \t]*"signingConfig": "default",[ \t]*\r?\n/, ""
    inreplace shell/"electron/src/main/module.json5", '"mainElement": "EntryAbility",',
              '"mainElement": "EntryAbility", "extractNativeLibs": true,'
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\r?\n    \],/m,
              <<~JSON5.chomp
                "requestPermissions": [
                      { "name": "ohos.permission.INTERNET" },
                      { "name": "ohos.permission.GET_NETWORK_INFO" }
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

    # Stage the publicly mirrored CLI into the build tree: no private image.
    clt = buildpath/"command-line-tools"
    hap_clt = formula_opt_bin("ohos-hap-clt")/"ohos-hap-clt"
    archive = resource("command-line-tools")
    archive.fetch
    system hap_clt.to_s, "stage", clt.to_s, archive.cached_download.to_s

    # The source root is an ES module; pin the CLT subtree back to CommonJS so
    # Node does not treat hvigorw.js as ESM.
    (clt/"package.json").write JSON.generate("type" => "commonjs")

    # ohpm and ohos_packing_tool need the staged SDK libraries on the search
    # path; the hvigor wrapper extends this same value for the assemble step.
    clang_lib = (clt/"sdk/default/openharmony/native/llvm/lib").glob("clang/*/lib/aarch64-linux-ohos").first
    odie "staged CLT missing clang runtime" if clang_lib.nil?
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] = "#{clt}/lib:#{clang_lib}"
    ENV.delete("NODE_OPTIONS")
    # The hvigor wrapper patches OHOS Node detection and HiLog logging that
    # were previously baked into the private image.
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd shell do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system hap_clt.to_s, "hvigor", clt.to_s, "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    libexec.install shell/"electron/build/default/outputs/default/electron-default-unsigned.hap" =>
                    "deepseek-harness-desktop-unsigned.hap"

    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"deepseek-harness-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    # READ_PASTEBOARD is required for pasting into the shell.
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.READ_PASTEBOARD
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # The HAP is delivered through app.json; deployment is an explicit
    # `ohos-app install deepseek-harness-desktop`. The upstream CLI stays independent.
    # Descriptor is written at build time with the real HAP digest and version.
    (pkgshare/"ohos").mkpath
    hap = libexec/"deepseek-harness-desktop-unsigned.hap"
    hap_sha = Digest::SHA256.file(hap).hexdigest
    descriptor = {
      "schema_version" => 1,
      "id"             => "social4hyq/core/deepseek-harness-desktop",
      "artifact"       => {
        "format"       => "hap",
        "path"         => "../../../libexec/deepseek-harness-desktop-unsigned.hap",
        "sha256"       => hap_sha,
        "api"          => 12,
        "abis"         => ["arm64-v8a"],
        "bundle_id"    => "com.social4hyq.deepseekharness",
        "version_name" => version.to_s,
        "version_code" => 1,
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
    refute_path_exists bin/"deepseek-harness-app"

    # Descriptor schema, id, digest and variants must match the HAP.
    descriptor = JSON.parse((pkgshare/"ohos/app.json").read)
    assert_equal 1, descriptor["schema_version"]
    assert_equal "social4hyq/core/deepseek-harness-desktop", descriptor["id"]
    hap = libexec/"deepseek-harness-desktop-unsigned.hap"
    assert_equal Digest::SHA256.file(hap).hexdigest, descriptor.dig("artifact", "sha256")
    assert_equal "com.social4hyq.deepseekharness", descriptor.dig("artifact", "bundle_id")
    assert_equal "acl", descriptor.dig("variants", "default")
    assert_equal Digest::SHA256.file(pkgshare/"module-acl.json").hexdigest,
                 descriptor.dig("variants", "definitions", "acl", "sha256")

    assert_match "libs/arm64-v8a/libelectron.so", shell_output("unzip -Z1 #{hap}")
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    system "node", "--test", tap_root/"Resources/deepseek-harness-desktop/tests/close-handler.test.cjs"
    waiting_source = shell_output("unzip -p #{hap} resources/resfile/resources/app/waiting.html")
    assert_match "ohos-app install deepseek-harness-desktop", waiting_source
    refute_match "{{", waiting_source
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_equal 0, placeholder.fetch("port")
    package = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/package.json"))
    assert_equal version.to_s, package.fetch("version")
    profile = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.deepseekharness", profile.fetch("app").fetch("bundleName")
    permissions = profile.fetch("module").fetch("requestPermissions").map { |entry| entry.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    system "unzip", "-tq", hap
  end
end
