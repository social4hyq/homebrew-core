class BrunoApp < Formula
  desc "Bruno API client desktop shell for OpenHarmony/HarmonyOS PC"
  homepage "https://www.usebruno.com/"
  # The official arm64 Linux .deb is the pinned vendor payload (nounzip: the
  # assembler selects the app.asar itself). It is downloaded again at install
  # time; the bottle ships only the tap-authored Electron-OHOS shell.
  url "https://github.com/usebruno/bruno/releases/download/v4.4.0/bruno_4.4.0_arm64_linux.deb",
      using: :nounzip
  sha256 "0264f6bd80deec178e89bdbe229e41747fa59e6fce1ef9bf9f3764924f362d7c"
  license "MIT"
  # Resources-only fix: declare READ_PASTEBOARD for clipboard support.
  revision 2

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bruno-app-v4.4.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9b06716ee768dcdabe71e514d6bc728c3ef4832dc68ecc7fae0dadff229163af"
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
    Resources/bruno-app/app/bruno-bootstrap.cjs
    Resources/bruno-app/assets/icon.png
    Resources/bruno-app/scripts/bruno-app.sh
    Resources/bruno-app/scripts/install-bruno-desktop.sh
    Resources/bruno-app/scripts/stage-ohos-shell.sh
    Resources/bruno-app/support/assemble-local-hap.py
    Resources/bruno-app/tests/assemble-local-hap.test.py
    Resources/bruno-app/tests/bruno-bootstrap.test.cjs
  ].freeze

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    super
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/bruno-app"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    support = buildpath/"bruno-support"
    support.mkpath
    RESOURCE_FILES.each do |file|
      cp tap_root/file, support/File.basename(file)
    end

    shell = buildpath/"libelectron/ohos_hap"
    project = buildpath/"bruno-ohos-shell"
    ENV["BRUNO_APP_VERSION"] = version.to_s
    system "bash", res/"scripts/stage-ohos-shell.sh", shell, project

    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "bruno-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['bruno-app']"
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

    libexec.install encrypted_hap => "bruno-app-shell-unsigned.hap"
    (libexec/"vendor.json").write JSON.generate(
      "url"     => stable.url.to_s,
      "sha256"  => stable.checksum.hexdigest,
      "version" => version.to_s,
      "file"    => File.basename(stable.url.to_s),
    )

    pkgshare.mkpath
    cp res/"scripts/install-bruno-desktop.sh", pkgshare/"install-desktop.sh"
    cp res/"support/assemble-local-hap.py", pkgshare/"assemble-local-hap.py"
    assemble_dir = pkgshare/"assemble"
    assemble_dir.mkpath
    cp res/"support/assemble-local-hap.py", assemble_dir
    cp res/"app/bruno-bootstrap.cjs", assemble_dir
    cp res/"app/bruno-bootstrap.cjs", pkgshare
    cp res/"scripts/stage-ohos-shell.sh", pkgshare
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    cp tap_root/"Resources/_shared/hap-app/enable-cookie-encryption.py", pkgshare
    cp res/"assets/icon.png", pkgshare
    cp res/"scripts/bruno-app.sh", libexec/"bruno-app.sh"
    chmod 0755, [pkgshare/"install-desktop.sh", libexec/"bruno-app.sh"]

    # Bruno runs under the weak sandbox (host file access). Expose the shell's
    # ACL module.json as an explicit ACL variant for the installer.
    shell_module = JSON.parse(
      Utils.safe_popen_read("unzip", "-p", libexec/"bruno-app-shell-unsigned.hap", "module.json"),
    )
    # READ_PASTEBOARD is user_grant: declaring it in module.json5 would fail the
    # build (it requires a reason string). Inject it into the ACL variant only,
    # which is signed at install time and does not go through hvigor.
    requested = shell_module.fetch("module").fetch("requestPermissions")
    unless requested.any? { |permission| permission["name"] == "ohos.permission.READ_PASTEBOARD" }
      requested << { "name" => "ohos.permission.READ_PASTEBOARD" }
    end
    (pkgshare/"module-acl.json").write JSON.generate(shell_module)

    # Run the assembler's package checks against the .deb Homebrew just
    # downloaded: a release that changes the app layout must fail this build,
    # not the user's install.
    ENV["BRUNO_APP_VENDOR_JSON"] = (libexec/"vendor.json").to_s
    mktemp("bruno-payload") do |scratch|
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
    (bin/"bruno-app").write_env_script libexec/"bruno-app.sh",
      BRUNO_APP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      BRUNO_APP_UNSIGNED_HAP:   libexec/"bruno-app-shell-unsigned.hap",
      BRUNO_APP_VENDOR_JSON:    libexec/"vendor.json",
      BRUNO_APP_ASSEMBLE_DIR:   assemble_dir,
      BRUNO_APP_MODULE_ACL:     pkgshare/"module-acl.json",
      BRUNO_APP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      BRUNO_APP_BREW_PREFIX:    formula_opt_prefix("app-installer").parent.parent,
      PATH:                     runtime_path
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "bruno-app", "com.social4hyq.bruno"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    hap = libexec/"bruno-app-shell-unsigned.hap"
    vendor = JSON.parse((libexec/"vendor.json").read)
    assert_equal version.to_s, vendor.fetch("version")
    assert_match(/\A[0-9a-f]{64}\z/, vendor.fetch("sha256"))
    assert_match(%r{\Ahttps://}, vendor.fetch("url"))
    assert_match "Usage: bruno-app", shell_output("#{bin}/bruno-app --help")

    module_json = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.bruno", module_json.dig("app", "bundleName")
    assert_equal version.to_s, module_json.dig("app", "versionName")
    permissions = module_json.dig("module", "requestPermissions").map { |item| item.fetch("name") }
    assert_includes permissions, "ohos.permission.CUSTOM_SANDBOX"
    assert_includes permissions, "ohos.permission.READ_WRITE_USER_FILE"
    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_permissions = acl.dig("module", "requestPermissions").map { |item| item.fetch("name") }
    assert_includes acl_permissions, "ohos.permission.CUSTOM_SANDBOX"
    # READ_PASTEBOARD is user_grant; it lives in the ACL variant only (a reason
    # string in module.json5 would fail the build).
    assert_includes acl_permissions, "ohos.permission.READ_PASTEBOARD"
    system "unzip", "-tq", hap

    system "python3", tap_root/"Resources/bruno-app/tests/assemble-local-hap.test.py"
    system "node", "--test", tap_root/"Resources/bruno-app/tests/bruno-bootstrap.test.cjs"
  end
end
