class PostmanApp < Formula
  desc "Postman API platform desktop shell for OpenHarmony/HarmonyOS PC"
  homepage "https://www.postman.com/downloads/"
  # The official arm64 Linux tarball is the pinned vendor payload (nounzip: the
  # assembler selects the app tree itself). It is downloaded again at install
  # time; the bottle ships only the tap-authored Electron-OHOS shell.
  url "https://dl.pstmn.io/download/version/12.38.0/linux_arm64",
      using: :nounzip
  version "12.38.0"
  sha256 "9827724c26a66ecca000ae5f1588e4d63a3e4a50f8cd622b948d307086a498e2"
  license :cannot_represent # Postman Terms / proprietary
  # Resources-only fix (starship shim) since v12.38.0; bump the package
  # revision so installed kegs pick up the change on `brew upgrade`.
  revision 1

  livecheck do
    skip "Postman publishes no machine-readable arm64 Linux version index"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/postman-app-v12.38.0-r4"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "146903fbcd397fce770c736835dea3bbc5db1682591603ce1fddaa9b552b1248"
  end

  depends_on "app-installer"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "python@3.15"
  depends_on "unzip"
  depends_on "zip"

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/enable-cookie-encryption.py
    Resources/_shared/hap-app/install-lib.sh
    Resources/postman-app/app/postman-bootstrap.cjs
    Resources/postman-app/app/starship-shim.cjs
    Resources/postman-app/assets/icon.png
    Resources/postman-app/scripts/install-postman-desktop.sh
    Resources/postman-app/scripts/postman-app.sh
    Resources/postman-app/scripts/stage-ohos-shell.sh
    Resources/postman-app/support/assemble-local-hap.py
    Resources/postman-app/tests/assemble-local-hap.test.py
    Resources/postman-app/tests/postman-bootstrap.test.cjs
    Resources/postman-app/tests/starship-shim.test.cjs
  ].freeze

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    super
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/postman-app"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    support = buildpath/"postman-support"
    support.mkpath
    RESOURCE_FILES.each do |file|
      cp tap_root/file, support/File.basename(file)
    end

    shell = buildpath/"libelectron/ohos_hap"
    project = buildpath/"postman-ohos-shell"
    ENV["POSTMAN_APP_VERSION"] = version.to_s
    system "bash", res/"scripts/stage-ohos-shell.sh", shell, project

    # The HarmonyOS CLT is proprietary and CI-only; never put signing
    # credentials in a bottle (users sign locally via app-installer).
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "postman-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['postman-app']"
    end

    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd project do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    shell_hap = project/"electron/build/default/outputs/default/electron-default-unsigned.hap"
    encrypted_hap = buildpath/"electron-default-cookie-unsigned.hap"
    system "python3", support/"enable-cookie-encryption.py", shell_hap, encrypted_hap

    # The bottle ships only the tap-authored shell; `postman-app install`
    # downloads Postman's official tarball and assembles the HAP locally on the
    # user's device, so the tap does not redistribute Postman binaries.
    libexec.install encrypted_hap => "postman-app-shell-unsigned.hap"
    (libexec/"vendor.json").write JSON.generate(
      "url"     => stable.url.to_s,
      "sha256"  => stable.checksum.hexdigest,
      "version" => version.to_s,
      "file"    => "postman-linux-arm64.tar.gz",
    )

    pkgshare.mkpath
    cp res/"scripts/install-postman-desktop.sh", pkgshare/"install-desktop.sh"
    cp res/"support/assemble-local-hap.py", pkgshare/"assemble-local-hap.py"
    assemble_dir = pkgshare/"assemble"
    assemble_dir.mkpath
    cp res/"support/assemble-local-hap.py", assemble_dir
    cp res/"app/postman-bootstrap.cjs", assemble_dir
    cp res/"app/starship-shim.cjs", assemble_dir
    cp res/"app/postman-bootstrap.cjs", pkgshare
    cp res/"scripts/stage-ohos-shell.sh", pkgshare
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    cp tap_root/"Resources/_shared/hap-app/enable-cookie-encryption.py", pkgshare
    cp res/"assets/icon.png", pkgshare
    cp res/"scripts/postman-app.sh", libexec/"postman-app.sh"
    chmod 0755, [pkgshare/"install-desktop.sh", libexec/"postman-app.sh"]

    # Postman needs the weak sandbox (host file access + host binary exec). The
    # shell HAP already declares the four ACL permissions; expose the same
    # module.json as an ACL variant so install-lib takes the explicit ACL path
    # and validates bundle consistency before signing.
    shell_module = JSON.parse(
      Utils.safe_popen_read("unzip", "-p", libexec/"postman-app-shell-unsigned.hap", "module.json"),
    )
    requested = shell_module.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.INTERNET ohos.permission.GET_NETWORK_INFO].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(shell_module)

    # Run the assembler's payload checks against the tarball Homebrew just
    # downloaded: a release that changes the app layout must fail this build,
    # not the user's install.
    ENV["POSTMAN_APP_VENDOR_JSON"] = (libexec/"vendor.json").to_s
    mktemp("postman-payload") do |scratch|
      system "python3", "-I", "-c", <<~PYTHON, assemble_dir/"assemble-local-hap.py", cached_download, scratch.tmpdir
        import importlib.util
        import sys
        from pathlib import Path

        sys.dont_write_bytecode = True
        spec = importlib.util.spec_from_file_location("assemble", sys.argv[1])
        assemble = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(assemble)
        assemble.selected_payload(Path(sys.argv[2]), Path(sys.argv[3]))
      PYTHON
    end

    runtime_path = [
      formula_opt_bin("app-installer"),
      formula_opt_bin("node"),
      formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      "$PATH",
    ].join(":")
    (bin/"postman-app").write_env_script libexec/"postman-app.sh",
      POSTMAN_APP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      POSTMAN_APP_UNSIGNED_HAP:   libexec/"postman-app-shell-unsigned.hap",
      POSTMAN_APP_VENDOR_JSON:    libexec/"vendor.json",
      POSTMAN_APP_ASSEMBLE_DIR:   assemble_dir,
      POSTMAN_APP_MODULE_ACL:     pkgshare/"module-acl.json",
      POSTMAN_APP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      POSTMAN_APP_BREW_PREFIX:    formula_opt_prefix("app-installer").parent.parent,
      PATH:                       runtime_path
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "postman-app", "com.social4hyq.postman"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    hap = libexec/"postman-app-shell-unsigned.hap"
    vendor = JSON.parse((libexec/"vendor.json").read)
    assert_equal version.to_s, vendor.fetch("version")
    assert_match(/\A[0-9a-f]{64}\z/, vendor.fetch("sha256"))
    assert_match(%r{\Ahttps://}, vendor.fetch("url"))
    assert_match "Usage: postman-app", shell_output("#{bin}/postman-app --help")

    # CLI matrix with fake hdc / app-installer.
    fake_bin = testpath/"cli-bin"
    fake_bin.mkpath
    hdc_log = testpath/"cli-hdc-log"
    (fake_bin/"hdc").write <<~SH
      #!/bin/sh
      printf '%s\\n' "$*" >> #{hdc_log}
      if [ "$1" = "shell" ] && [ "$2" = "ps -ef" ]; then
        if [ -z "${FAKE_STOPPED:-}" ]; then
          printf '%s\\n' "u 1 1 1 1 ? 00:00:00 com.social4hyq.postman"
        fi
      fi
    SH
    chmod 0755, fake_bin/"hdc"
    installer_args = testpath/"cli-installer-args"
    (fake_bin/"app-installer").write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{installer_args}
    SH
    chmod 0755, fake_bin/"app-installer"
    cli_env = {
      "POSTMAN_APP_HDC"       => fake_bin/"hdc",
      "POSTMAN_APP_INSTALLER" => fake_bin/"app-installer",
      "PATH"                  => "#{fake_bin}:#{ENV.fetch("PATH")}",
    }
    with_env(cli_env) do
      shell_output("#{bin}/postman-app start --device tablet-1")
      assert_match "-t tablet-1 shell aa start", (testpath/"cli-hdc-log").read
      shell_output("#{bin}/postman-app stop")
      assert_match "shell aa force-stop com.social4hyq.postman", (testpath/"cli-hdc-log").read
      assert_match "running", shell_output("#{bin}/postman-app status")
      with_env("FAKE_STOPPED" => "1") do
        assert_match "not running", shell_output("#{bin}/postman-app status 2>&1", 1)
      end
      shell_output("#{bin}/postman-app uninstall --purge --device tablet-1")
      assert_equal %w[uninstall --bundle-id com.social4hyq.postman --device tablet-1 --purge],
                   installer_args.read.lines(chomp: true)
    end

    # Real HAP assertions: bundle, version, weak-sandbox ACL permissions, icon.
    module_json = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.postman", module_json.dig("app", "bundleName")
    assert_equal version.to_s, module_json.dig("app", "versionName")
    major, minor, patch = version.to_s.split(".").map(&:to_i)
    expected_code = format("%<major>02d%<minor>04d%<patch>05d",
                           major: major, minor: minor, patch: patch).to_i / 100
    assert_equal expected_code, module_json.dig("app", "versionCode")
    permissions = module_json.dig("module", "requestPermissions").map { |item| item.fetch("name") }
    assert_includes permissions, "ohos.permission.INTERNET"
    assert_includes permissions, "ohos.permission.CUSTOM_SANDBOX"
    assert_includes permissions, "ohos.permission.READ_WRITE_USER_FILE"
    # The wrapper must expose an ACL variant (weak sandbox is required).
    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_permissions = acl.dig("module", "requestPermissions").map { |item| item.fetch("name") }
    assert_includes acl_permissions, "ohos.permission.CUSTOM_SANDBOX"
    assert_includes acl_permissions, "ohos.permission.READ_WRITE_USER_FILE"
    listing = shell_output("unzip -Z1 #{hap}")
    refute_match "resources/resfile/resources/app/vendor/main.js", listing
    system "unzip", "-tq", hap

    icon = testpath/"postman-icon.png"
    icon.write Utils.safe_popen_read("unzip", "-p", hap, "resources/base/media/app_icon.png")
    assert_equal Digest::SHA256.file(tap_root/"Resources/postman-app/assets/icon.png").hexdigest,
                 Digest::SHA256.file(icon).hexdigest

    # Assembler checks: trimmed native addons are rejected, valid layout passes.
    system "python3", tap_root/"Resources/postman-app/tests/assemble-local-hap.test.py"
    system "node", "--test", tap_root/"Resources/postman-app/tests/postman-bootstrap.test.cjs"
    system "node", "--test", tap_root/"Resources/postman-app/tests/starship-shim.test.cjs"
  end
end
