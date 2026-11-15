class DeepseekHarnessDesktop < Formula
  desc "Desktop shell for the DeepSeek Harness agent (Electron window on local dsh web)"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://github.com/deepseek-ai/deepseek-harness/archive/refs/tags/dsh-v0.2.2-rc.2.tar.gz"
  sha256 "d376fe64ec4b7c9b5837fb1155ed3a48e7e0e5f5b0aae0b91d9fb836daa8c20e"
  license :cannot_represent

  livecheck do
    url "https://github.com/deepseek-ai/deepseek-harness.git"
    regex(/^dsh-v(\d+\.\d+\.\d+(?:-(?:alpha|rc)\.\d+)?)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/deepseek-harness-desktop-v0.2.2-rc.2-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fc5f0189db7e51cb718393dfc405edae9d2c7cd93b41358fb126e7f1e140ac18"
  end

  depends_on "node" => :build
  depends_on "curl"
  depends_on "deepseek-harness"
  depends_on "hap-installer"
  depends_on "ohos-sdk-toolchains"
  depends_on "zip"

  resource "electron-ohos" do
    url "https://atomgit.com/social4hyq/homebrew-core/releases/download/electron-ohos-v34.9.0-20261030.1/v34.9.0-20261030.1-release.zip"
    sha256 "599e97b3d8b1e5071a2387496104b443e58079a5f5c165b0114e65ffc601df3a"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_132.tar.gz", "-C", buildpath
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

    inreplace shell/"build-profile.json5", "        \"signingConfig\": \"default\",\n", ""
    inreplace shell/"electron/src/main/module.json5", "    \"mainElement\": \"EntryAbility\",\n",
              "    \"mainElement\": \"EntryAbility\",\n    \"extractNativeLibs\": true,\n"
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\n    \],/m,
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
      DSH_DESKTOP_NODE_DEFAULT:   formula_opt_bin("node")/"node",
      DSH_DESKTOP_VERSION:        version.to_s,
      PATH:                       "#{formula_opt_bin("deepseek-harness")}:$PATH"
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
    signer_args = testpath/"hap-installer-sign-args"
    hdc_log = testpath/"hdc-log"

    fake_devecocli = fake_bin/"devecocli"
    fake_devecocli.write <<~SH
      #!/bin/sh
      case "$1" in
        auth|signature) exit 0 ;;
        create)
          while [ $# -gt 0 ]; do
            if [ "$1" = "--project-path" ]; then project="$2"; fi
            shift
          done
          mkdir -p "$project/entry/src/main"
          printf '{\\n  "module": {\\n    "name": "entry",\\n    "type": "entry"\\n  }\\n}\\n' > "$project/entry/src/main/module.json5"
          printf '{"app":{"signingConfigs":[]}}\\n' > "$project/build-profile.json5"
          ;;
      esac
    SH
    chmod 0755, fake_devecocli

    fake_signer = fake_bin/"hap-installer-sign"
    fake_signer.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{signer_args}
      out=""
      while [ $# -gt 0 ]; do
        case "$1" in
          --hap) cp "$2" #{injected_copy}; shift 2 ;;
          --output) out="$2"; shift 2 ;;
          *) shift ;;
        esac
      done
      printf 'signed' > "$out"
    SH
    chmod 0755, fake_signer

    fake_hdc = fake_bin/"hdc"
    fake_hdc.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" >> #{hdc_log}
      case "$*" in
        *"list targets"*) printf '%s\\n' "127.0.0.1:34561 Connected" ;;
        *"bm install"*) printf '%s\\n' "install bundle successfully" ;;
      esac
    SH
    chmod 0755, fake_hdc

    ENV.prepend_path "PATH", fake_bin
    ENV.prepend_path "PATH", formula_opt_bin("node").to_s
    ENV["DSH_DESKTOP_HDC"] = (fake_bin/"hdc").to_s
    ENV["DSH_DESKTOP_CLT_CACHE"] = (testpath/"clt-cache").to_s

    assert_match "installed and started", shell_output("#{bin}/deepseek-harness-desktop install")
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
    project_dir = Pathname.new(Dir.home)/".hap-installer/projects/com.social4hyq.deepseekharness"
    assert_match "CUSTOM_SANDBOX", (project_dir/"entry/src/main/module.json5").read
    signer = signer_args.read.lines(chomp: true)
    assert_equal (project_dir/"build-profile.json5").to_s, signer[signer.index("--profile") + 1]
    assert_match "aa start -a EntryAbility -b com.social4hyq.deepseekharness -m electron", hdc_log.read

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
