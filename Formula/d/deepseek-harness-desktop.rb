class DeepseekHarnessDesktop < Formula
  desc "Desktop shell for the DeepSeek Harness agent (Electron window on local dsh web)"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://github.com/deepseek-ai/deepseek-harness/archive/refs/tags/dsh-v0.2.2-rc.3.tar.gz"
  sha256 "bf6d668e52a26edf98aa2ef7960e240c8d9afcefbad2b09887a2cb1e14001dd5"
  license :cannot_represent

  revision 3

  livecheck do
    url "https://github.com/deepseek-ai/deepseek-harness.git"
    regex(/^dsh-v(\d+\.\d+\.\d+(?:-(?:alpha|rc)\.\d+)?)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/deepseek-harness-desktop-v0.2.2-rc.3-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "243f69fd70892a992e456bcaae99f1a816b365d4b8412fa94772fe7b5b379218"
  end

  depends_on "curl"
  depends_on "deepseek-harness"
  depends_on "hap-installer"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "zip"

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    cp tap_root/"Patches/deepseek-harness-desktop/app/main.cjs", app
    cp tap_root/"Patches/deepseek-harness-desktop/app/package.json", app
    cp tap_root/"Patches/deepseek-harness-desktop/app/config.json", app
    cp tap_root/"Patches/deepseek-harness-desktop/app/waiting.html", app

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.deepseekharness"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp tap_root/"Patches/deepseek-harness-desktop/assets/icon.png", shell/"AppScope/resources/base/media"/name
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

    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "deepseek-harness-desktop builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES"
    end

    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    if hard_cap > 65_536
      Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536)
    end

    cd shell do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    libexec.install shell/"electron/build/default/outputs/default/electron-default-unsigned.hap" =>
                    "deepseek-harness-desktop-unsigned.hap"

    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"deepseek-harness-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    (pkgshare/"install-desktop.sh").write(
      (tap_root/"Patches/deepseek-harness-desktop/scripts/install-desktop.sh").read,
    )
    chmod 0755, pkgshare/"install-desktop.sh"
    (libexec/"deepseek-harness-desktop.sh").write(
      (tap_root/"Patches/deepseek-harness-desktop/scripts/deepseek-harness-desktop.sh").read,
    )
    chmod 0755, libexec/"deepseek-harness-desktop.sh"
    (bin/"deepseek-harness-desktop").write_env_script opt_libexec/"deepseek-harness-desktop.sh",
      DSH_DESKTOP_UNSIGNED_HAP:   opt_libexec/"deepseek-harness-desktop-unsigned.hap",
      DSH_DESKTOP_INSTALL_SCRIPT: opt_pkgshare/"install-desktop.sh",
      DSH_DESKTOP_MODULE_ACL:     opt_pkgshare/"module-acl.json",
      DSH_DESKTOP_DSH_BIN:        formula_opt_bin("deepseek-harness")/"dsh",
      DSH_DESKTOP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      DSH_DESKTOP_VERSION:        version.to_s,
      PATH:                       "#{formula_opt_bin("node")}:#{formula_opt_bin("deepseek-harness")}:$PATH"
  end

  def caveats
    <<~EOS
      The desktop HAP is unsigned in the bottle. Connect and unlock the device,
      then run `deepseek-harness-desktop install`.

      The shell starts `dsh web` itself and loads the authenticated URL printed
      by that process. This needs weak-sandbox ACLs, granted through a local
      debug profile generated by hap-installer. Closing the shell stops only
      the backend it started; a CLI-managed `deepseek-harness-desktop serve`
      instance remains available to other clients.

      The formula follows the deepseek-harness upstream version. If the CLI and
      desktop versions differ, install/start prints a warning but does not stop.
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "Usage: deepseek-harness-desktop", shell_output("#{bin}/deepseek-harness-desktop --help")

    fake_bin = testpath/"bin"
    fake_bin.mkpath
    injected_copy = testpath/"injected.hap"
    installer_args = testpath/"hap-installer-args"

    (fake_bin/"devecocli").write "#!/bin/sh\nexit 99\n"
    chmod 0755, fake_bin/"devecocli"
    fake_installer = fake_bin/"hap-installer"
    fake_installer.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{installer_args}
      while [ $# -gt 0 ]; do
        case "$1" in
          --hap) cp "$2" #{injected_copy}; shift 2 ;;
          *) shift ;;
        esac
      done
    SH
    chmod 0755, fake_installer
    fake_hdc = fake_bin/"hdc"
    fake_hdc.write "#!/bin/sh\nexit 99\n"
    chmod 0755, fake_hdc

    ENV.prepend_path "PATH", fake_bin
    ENV.prepend_path "PATH", formula_opt_bin("node").to_s
    ENV["DSH_DESKTOP_HDC"] = (fake_bin/"hdc").to_s

    assert_match "installed", shell_output("#{bin}/deepseek-harness-desktop install")
    config = JSON.parse(shell_output("unzip -p #{injected_copy} resources/resfile/resources/app/config.json"))
    assert_operator config.fetch("port"), :>, 0
    refute_empty config.fetch("dsh")
    assert_equal Dir.home, config.dig("host", "home")
    acl_module = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    acl_permissions = acl_module.fetch("module").fetch("requestPermissions").map { |entry| entry.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO
                    ohos.permission.INTERNET ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_permissions.sort
    installer = installer_args.read.lines(chomp: true)
    assert_equal "com.social4hyq.deepseekharness", installer[installer.index("--bundle-id") + 1]
    assert_equal "electron", installer[installer.index("--module") + 1]
    assert_equal (fake_bin/"hdc").to_s, installer[installer.index("--hdc") + 1]
    refute_path_exists Pathname.new(Dir.home)/".hap-installer"
    assert_match "installed", shell_output("#{bin}/deepseek-harness-desktop install --device chosen")
    installer = installer_args.read.lines(chomp: true)
    assert_equal "chosen", installer[installer.index("--device") + 1]

    assert_match "serving at", shell_output("#{bin}/deepseek-harness-desktop serve")
    assert_match "healthy", shell_output("#{bin}/deepseek-harness-desktop status")
    assert_match "stopped", shell_output("#{bin}/deepseek-harness-desktop stop")

    serve_only_args = testpath/"hdc-start-args"
    fake_hdc.delete
    fake_hdc.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{serve_only_args}
    SH
    chmod 0755, fake_hdc
    assert_match "serving at", shell_output("#{bin}/deepseek-harness-desktop start --serve-only")
    assert_match "opened", shell_output("#{bin}/deepseek-harness-desktop start")
    assert_equal %w[shell aa start -a EntryAbility -b com.social4hyq.deepseekharness -m electron],
                 serve_only_args.read.lines(chomp: true)
    assert_match "stopped", shell_output("#{bin}/deepseek-harness-desktop stop")

    hap = libexec/"deepseek-harness-desktop-unsigned.hap"
    assert_path_exists hap
    assert_path_exists pkgshare/"module-acl.json"
    listing = shell_output("unzip -l #{hap}")
    assert_match "pack.info", listing
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "resources/resfile/resources/app/main.cjs", listing
    assert_match "resources/resfile/resources/app/waiting.html", listing
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
