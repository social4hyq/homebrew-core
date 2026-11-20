class CodexApp < Formula
  desc "ChatGPT desktop shell for OpenHarmony/HarmonyOS PC"
  homepage "https://learn.chatgpt.com/docs/linux/linux-app"
  url "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_arm64.deb",
      using: :nounzip
  version "26.1111.71704"
  sha256 "f0550dee1f99127d357ad760aef739c557d49bd67728d2f105d00a7a4780f740"
  license :cannot_represent # OpenAI service and software terms
  revision 2

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/codex-app-v26.1111.71704-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "231cf0e75e0e109ca99f9ccf4eb5fc4729c6fd52fa43afd2811475a430ed0731"
  end

  depends_on "binutils" => :build
  depends_on "app-installer"
  depends_on "codex"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "python@3.15"
  depends_on "unzip"
  depends_on "zip"

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  # The shell staging files and official ChatGPT icon are listed literally so
  # the tap's resource audit retains every file used by the formula.
  RESOURCE_FILES = %w[
    Resources/codex-app/assets/icon.png
    Resources/codex-app/app/chatgpt-bootstrap.cjs
    Resources/codex-app/scripts/codex-app.sh
    Resources/codex-app/scripts/install-chatgpt-desktop.sh
    Resources/codex-app/scripts/stage-ohos-shell.sh
    Resources/codex-app/support/assemble-local-hap.py
    Resources/codex-app/support/enable-cookie-encryption.py
    Resources/codex-app/tests/chatgpt-bootstrap.test.cjs
    Resources/codex-app/tests/assemble-local-hap.test.py
    Resources/_shared/hap-app/install-lib.sh
  ].freeze

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    super
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/codex-app"
    RESOURCE_FILES.each do |file|
      odie "missing tap resource: #{file}" unless (tap_root/file).exist?
    end

    support = buildpath/"codex-app-support"
    support.mkpath
    RESOURCE_FILES.grep(%r{/app/|/support/}).each do |file|
      cp tap_root/file, support/File.basename(file)
    end

    shell = buildpath/"libelectron/ohos_hap"
    project = buildpath/"chatgpt-ohos-shell"
    system "bash", res/"scripts/stage-ohos-shell.sh", shell, project, version.to_s

    # Electron's HAP build tooling is proprietary and is provided by the
    # dedicated electron-ohos-ci runner. Signing remains a local user action.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "codex-app builds only in electron-ohos-ci; configure OHOS_CI_IMAGE_OVERRIDES"
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

    cd project do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    shell_hap = project/"electron/build/default/outputs/default/electron-default-unsigned.hap"
    encrypted_hap = buildpath/"electron-default-cookie-unsigned.hap"
    assembled_hap = buildpath/"chatgpt-desktop-assembled-unsigned.hap"
    system "python3", support/"enable-cookie-encryption.py", shell_hap, encrypted_hap
    system "python3", support/"assemble-local-hap.py", encrypted_hap,
           stable.cached_download, assembled_hap

    libexec.install assembled_hap => "codex-app-unsigned.hap"
    pkgshare.mkpath
    cp res/"scripts/codex-app.sh", libexec/"codex-app.sh"
    cp res/"scripts/codex-app.sh", pkgshare/"codex-app.sh"
    cp res/"scripts/install-chatgpt-desktop.sh", pkgshare/"install-desktop.sh"
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    cp res/"scripts/stage-ohos-shell.sh", pkgshare/"stage-ohos-shell.sh"
    cp support/"assemble-local-hap.py", pkgshare/"assemble-local-hap.py"
    cp support/"enable-cookie-encryption.py", pkgshare/"enable-cookie-encryption.py"
    chmod 0755, [libexec/"codex-app.sh", pkgshare/"codex-app.sh",
                 pkgshare/"install-desktop.sh", pkgshare/"hap-app-install-lib.sh",
                 pkgshare/"stage-ohos-shell.sh"]

    module_json = JSON.parse(
      Utils.safe_popen_read("unzip", "-p", libexec/"codex-app-unsigned.hap", "module.json"),
    )
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.READ_PASTEBOARD ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    runtime_path = [
      formula_opt_bin("app-installer"),
      formula_opt_bin("codex"),
      formula_opt_bin("ohos-sdk-toolchains"),
      formula_opt_bin("node"),
      formula_opt_prefix("python@3.15")/"bin",
      "$PATH",
    ].join(":")
    (bin/"codex-app").write_env_script libexec/"codex-app.sh",
      CHATGPT_APP_HDC:            formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      CHATGPT_APP_UNSIGNED_HAP:   libexec/"codex-app-unsigned.hap",
      CHATGPT_APP_CODEX_CLI:      formula_opt_bin("codex")/"codex",
      CHATGPT_APP_BREW_PREFIX:    formula_opt_prefix("codex").parent.parent,
      CHATGPT_APP_MODULE_ACL:     pkgshare/"module-acl.json",
      CHATGPT_APP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      CHATGPT_APP_INSTALLER:      formula_opt_bin("app-installer"),
      PATH:                       runtime_path
  end

  post_install_steps do
    run "{HOMEBREW_PREFIX}/bin/hap-app",
        args: ["auto-install", "codex-app", "com.social4hyq.chatgpt"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  def caveats
    <<~EOS
      `brew install` runs `codex-app install` automatically once the device is
      connected and the Huawei Developer login is done; otherwise it is queued:
      `hap-app install-pending` finishes it. To install by hand, run
      `codex-app install` to create a local debug signing profile, sign the HAP,
      and install ChatGPT. A connected, unlocked OpenHarmony PC device is
      required. The app starts the stable Homebrew `codex` CLI when
      opened. Installation injects host paths into a private signed HAP copy
      and requests ACL permissions for host project access. A Huawei Developer
      login is required for the first ACL-capable signing. Use
      `codex-app install --no-acl` to install a strong-sandbox variant; host
      Codex features will not work in that variant.
    EOS
  end

  test do
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    hap = libexec/"codex-app-unsigned.hap"
    assert_path_exists hap
    assert_match "Usage: codex-app", shell_output("#{bin}/codex-app --help")

    %w[
      assemble-local-hap.py
      enable-cookie-encryption.py
    ].each { |file| assert_path_exists pkgshare/file }
    assert_match "shell deb output", shell_output("python3 #{pkgshare}/assemble-local-hap.py --help")
    assert_match "source output", shell_output("python3 #{pkgshare}/enable-cookie-encryption.py --help")
    system "node", "--check", tap_root/"Resources/codex-app/app/chatgpt-bootstrap.cjs"
    system "node", "--test", tap_root/"Resources/codex-app/tests/chatgpt-bootstrap.test.cjs"
    system "python3", tap_root/"Resources/codex-app/tests/assemble-local-hap.test.py"

    module_json = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.chatgpt", module_json.dig("app", "bundleName")
    assert_equal version.to_s, module_json.dig("app", "versionName")
    major, minor, build = version.to_s.split(".").map(&:to_i)
    code = format("%<major>02d%<minor>04d%<build>05d", major: major, minor: minor, build: build).to_i / 100
    assert_equal code, module_json.dig("app", "versionCode")
    assert_equal "electron", module_json.dig("module", "name")
    permissions = module_json.dig("module", "requestPermissions").to_a.map { |item| item.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_permissions = acl.dig("module", "requestPermissions").map { |item| item.fetch("name") }
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.READ_PASTEBOARD ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |name|
      assert_includes acl_permissions, name
    end
    bootstrap = (tap_root/"Resources/codex-app/app/chatgpt-bootstrap.cjs").read
    installer = (tap_root/"Resources/codex-app/scripts/install-chatgpt-desktop.sh").read
    assert_match "CODEX_CLI_PATH", bootstrap
    assert_match "chatgpt-host-config.json", installer
    listing = shell_output("unzip -Z1 #{hap}")
    assert_match "resources/resfile/resources/app/vendor.asar", listing
    assert_match "resources/resfile/resources/app/vendor.asar.unpacked/", listing
    assert_match "resources/resfile/resources/codex", listing
    assert_match "resources/resfile/resources/codex-code-mode-host", listing
    assert_match "resources.index", listing
    assert_match "ChatGPT", shell_output("unzip -p #{hap} resources.index | strings")
    icon = testpath/"chatgpt-icon.png"
    icon.write Utils.safe_popen_read("unzip", "-p", hap, "resources/base/media/app_icon.png")
    assert_equal "cfe031774dd6aabdceca35338f329bc4844592767d043b7b4a56d8fb097dffd0",
                 Digest::SHA256.file(icon).hexdigest
    system "unzip", "-tq", hap

    # Exercise host-config injection and both signing profiles without a
    # device or real signing credentials.
    fixture_dir = testpath/"install-fixture"
    fixture_dir.mkpath
    fixture_manifest = { "app"    => { "bundleName" => "com.social4hyq.chatgpt" },
                         "module" => { "name" => "electron", "requestPermissions" => [
                           { "name" => "ohos.permission.INTERNET" },
                           { "name" => "ohos.permission.GET_NETWORK_INFO" },
                         ] } }
    (fixture_dir/"module.json").write JSON.generate(fixture_manifest)
    fixture_hap = testpath/"install-fixture.hap"
    cd fixture_dir do
      system "zip", "-q", fixture_hap, "module.json"
    end
    fake_bin = testpath/"fake-bin"
    fake_bin.mkpath
    fake_installer = fake_bin/"app-installer"
    fake_installer.write <<~SH
      #!/usr/bin/env bash
      set -euo pipefail
      input="" output=""
      while (($#)); do
        case "$1" in
          --hap) input="$2"; shift 2 ;;
          --signed-hap) output="$2"; shift 2 ;;
          *) shift ;;
        esac
      done
      cp "$input" "$output"
      echo installed
    SH
    chmod 0755, fake_installer
    host_home = testpath/"host-home"
    host_home.mkpath
    test_env = {
      "CHATGPT_APP_UNSIGNED_HAP" => fixture_hap.to_s,
      "CHATGPT_APP_MODULE_ACL"   => (pkgshare/"module-acl.json").to_s,
      "CHATGPT_APP_CODEX_CLI"    => (formula_opt_bin("codex")/"codex").to_s,
      "CHATGPT_APP_BREW_PREFIX"  => formula_opt_prefix("codex").parent.parent.to_s,
      "CHATGPT_APP_HOST_HOME"    => host_home.to_s,
      "CHATGPT_APP_HDC"          => "fake-hdc",
      "TMPDIR"                   => testpath.to_s,
      "CODEX_HOME"               => "#{host_home}/.codex",
      "PATH"                     => "#{fake_bin}:#{ENV.fetch("PATH")}",
    }
    install_variant = lambda do |*args|
      previous_env = test_env.keys.to_h { |name| [name, ENV[name]] }
      test_env.each { |name, value| ENV[name] = value }
      begin
        system "bash", pkgshare/"install-desktop.sh", *args
      ensure
        previous_env.each do |name, value|
          value ? ENV[name] = value : ENV.delete(name)
        end
      end
    end
    install_variant.call("--keep")
    injected = testpath/"codex-app-signed.hap"
    injected_manifest = JSON.parse(shell_output("unzip -p #{injected} module.json"))
    assert_includes injected_manifest.dig("module", "requestPermissions").map { |item| item.fetch("name") },
                    "ohos.permission.CUSTOM_SANDBOX"
    host_config = JSON.parse(shell_output(
                               "unzip -p #{injected} resources/resfile/resources/app/chatgpt-host-config.json",
                             ))
    assert_equal host_home.to_s, host_config.fetch("home")
    assert_equal "#{host_home}/.codex", host_config.fetch("codexHome")
    assert_equal "#{formula_opt_bin("codex")}/codex", host_config.fetch("codexCli")

    install_variant.call("--no-acl", "--keep")
    strong_sandbox = JSON.parse(shell_output("unzip -p #{injected} module.json"))
    strong_permissions = strong_sandbox.dig("module", "requestPermissions").map { |item| item.fetch("name") }
    assert_empty strong_permissions.grep(/CUSTOM_SANDBOX|READ_WRITE_USER_FILE/)
  end
end
