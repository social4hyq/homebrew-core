class AntigravityApp < Formula
  desc "Google Antigravity desktop shell for OpenHarmony/HarmonyOS PC"
  homepage "https://antigravity.google/download"
  url "https://storage.googleapis.com/antigravity-public/antigravity-hub/" \
      "2.34.0-5887025308631040/linux-arm/Antigravity.tar.gz"
  sha256 "91f31ce50c795e0571e7922511119ff3e7afc2ee4f640a97d69dbad2063c1866"
  license :cannot_represent # Google Terms of Service; closed-source prebuilt desktop app
  revision 5

  livecheck do
    url :homepage
    regex(%r{antigravity-hub/(\d+(?:\.\d+)+)-\d+}i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/antigravity-app-v2.34.0-r4"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c40d7fe19591bb85f584a9f95af157e490b681d247fd4631abc4562147449327"
  end

  depends_on "app-installer"
  depends_on "glibc"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "ohos-selfsign"
  depends_on "patchelf"
  depends_on "python@3.15"
  depends_on "unzip"
  depends_on "zip"

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  # The bottle ships the tap-authored HAP shell only. The official engine is
  # downloaded and prepared on the user's device by `antigravity-app install`.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/enable-cookie-encryption.py
    Resources/_shared/hap-app/install-lib.sh
    Resources/antigravity-app/app/antigravity-bootstrap.cjs
    Resources/antigravity-app/assets/icon.png
    Resources/antigravity-app/scripts/antigravity-app.sh
    Resources/antigravity-app/scripts/install-antigravity-desktop.sh
    Resources/antigravity-app/scripts/stage-ohos-shell.sh
    Resources/antigravity-app/support/assemble-local-hap.py
  ].freeze

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    super
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    support = buildpath/"antigravity-app-support"
    support.mkpath
    RESOURCE_FILES.grep(%r{/app/|/support/}).each do |file|
      cp tap_root/file, support/File.basename(file)
    end

    shell = buildpath/"libelectron/ohos_hap"
    project = buildpath/"antigravity-ohos-shell"
    system "bash", tap_root/"Resources/antigravity-app/scripts/stage-ohos-shell.sh",
           shell, project, version.to_s

    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "antigravity-app builds only in electron-ohos-ci; configure OHOS_CI_IMAGE_OVERRIDES"
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
    system "python3", tap_root/"Resources/_shared/hap-app/enable-cookie-encryption.py",
           shell_hap, encrypted_hap

    libexec.install encrypted_hap => "antigravity-app-shell-unsigned.hap"
    (libexec/"vendor.json").write JSON.generate(
      "url"     => stable.url.to_s,
      "sha256"  => stable.checksum.hexdigest,
      "version" => version.to_s,
      "file"    => "Antigravity.tar.gz",
    )

    pkgshare.mkpath
    cp tap_root/"Resources/antigravity-app/scripts/antigravity-app.sh", libexec/"antigravity-app.sh"
    cp tap_root/"Resources/antigravity-app/scripts/antigravity-app.sh", pkgshare/"antigravity-app.sh"
    cp tap_root/"Resources/antigravity-app/scripts/install-antigravity-desktop.sh", pkgshare/"install-desktop.sh"
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    cp tap_root/"Resources/antigravity-app/scripts/stage-ohos-shell.sh", pkgshare/"stage-ohos-shell.sh"
    assemble_dir = pkgshare/"assemble"
    assemble_dir.mkpath
    cp support/"assemble-local-hap.py", assemble_dir
    cp support/"antigravity-bootstrap.cjs", assemble_dir

    # Fail the build, not the user's install, if the pinned vendor package no
    # longer contains the engine the assembler expects.
    ENV["ANTIGRAVITY_APP_VENDOR_JSON"] = (libexec/"vendor.json").to_s
    verify_script = assemble_dir/"assemble-local-hap.py"
    verify_pin = (libexec/"vendor.json").to_s
    system "python3", "-I", "-c", <<~PYTHON, verify_script, cached_download, verify_pin
      import importlib.util
      import sys
      from pathlib import Path

      sys.dont_write_bytecode = True
      spec = importlib.util.spec_from_file_location("assemble", sys.argv[1])
      assemble = importlib.util.module_from_spec(spec)
      spec.loader.exec_module(assemble)
      assemble.verify_tarball(Path(sys.argv[2]), Path(sys.argv[3]))
    PYTHON

    module_json = JSON.parse(
      Utils.safe_popen_read("unzip", "-p", libexec/"antigravity-app-shell-unsigned.hap", "module.json"),
    )
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    chmod 0755, [libexec/"antigravity-app.sh", pkgshare/"antigravity-app.sh",
                 pkgshare/"install-desktop.sh", pkgshare/"hap-app-install-lib.sh",
                 pkgshare/"stage-ohos-shell.sh"]

    runtime_path = [
      formula_opt_bin("app-installer"),
      formula_opt_bin("ohos-sdk-toolchains"),
      formula_opt_bin("node"),
      formula_opt_prefix("patchelf")/"bin",
      formula_opt_prefix("ohos-selfsign")/"bin",
      formula_opt_prefix("python@3.15")/"bin",
      "$PATH",
    ].join(":")
    (bin/"antigravity-app").write_env_script libexec/"antigravity-app.sh",
      ANTIGRAVITY_APP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      ANTIGRAVITY_APP_UNSIGNED_HAP:   libexec/"antigravity-app-shell-unsigned.hap",
      ANTIGRAVITY_APP_VENDOR_JSON:    libexec/"vendor.json",
      ANTIGRAVITY_APP_LIBEXEC:        assemble_dir,
      ANTIGRAVITY_APP_BREW_PREFIX:    HOMEBREW_PREFIX,
      ANTIGRAVITY_APP_MODULE_ACL:     pkgshare/"module-acl.json",
      ANTIGRAVITY_APP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      PATH:                           runtime_path
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "antigravity-app", "com.social4hyq.antigravity"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    vendor = JSON.parse((libexec/"vendor.json").read)
    assert_equal version.to_s, vendor.fetch("version")
    assert_match(/\A[0-9a-f]{64}\z/, vendor.fetch("sha256"))
    assert_match "https://", vendor.fetch("url")
    assert_match "Usage: antigravity-app", shell_output("#{bin}/antigravity-app --help")
    assert_path_exists libexec/"antigravity-app-shell-unsigned.hap"
  end
end
