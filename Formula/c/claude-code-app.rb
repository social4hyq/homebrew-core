class ClaudeCodeApp < Formula
  desc "Claude Code Desktop shell for OpenHarmony/HarmonyOS PC"
  homepage "https://code.claude.com/docs/en/desktop-linux"
  url "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_5.11492.5_arm64.deb",
      using: :nounzip
  version "5.11492.5"
  sha256 "fe6cd8a70f96b96eb4e6b647300cfaee6aaff4ce133a0fbbe11c2cdb775f5a6a"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 3

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-app-v5.11492.5-r5"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "534cfb71a710f5e367bf8a96a8c630614959b6953c72870f7cdd3e353a12bdd5"
  end

  depends_on "binutils" => :build
  depends_on "app-installer"
  depends_on "claude-code.latest"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "python@3.15"
  depends_on "unzip"

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/claude-code-app/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
      directory "libelectron/ohos_hap"
    end
  end

  # Shell packaging sources and the official Claude app icon are tap-authored
  # or extracted from the pinned upstream package. List every file literally so
  # the tap's unused-resource audit retains the directory.
  RESOURCE_FILES = %w[
    Resources/claude-code-app/assets/icon.png
    Resources/claude-code-app/scripts/claude-code-app.sh
    Resources/claude-code-app/scripts/install-claude-code-desktop.sh
    Resources/claude-code-app/scripts/stage-ohos-shell.sh
    Resources/claude-code-app/app/claude-bootstrap.cjs
    Resources/claude-code-app/app/claude-code-platform-patch.cjs
    Resources/claude-code-app/app/claude-launch-bridge.cjs
    Resources/claude-code-app/app/claude-ohos-config.cjs
    Resources/claude-code-app/support/assemble-local-hap.py
    Resources/claude-code-app/support/enable-cookie-encryption.py
    Resources/claude-code-app/support/patch-code-runtime-hap.py
    Resources/claude-code-app/tests/claude-bootstrap.test.cjs
    Resources/claude-code-app/tests/claude-code-platform-patch.test.cjs
    Resources/claude-code-app/tests/claude-launch-bridge.test.cjs
    Resources/claude-code-app/tests/claude-ohos-config.test.cjs
  ].freeze

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    super
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/claude-code-app"
    RESOURCE_FILES.each do |file|
      odie "missing tap resource: #{file}" unless (tap_root/file).exist?
    end
    support = buildpath/"claude-code-support"
    support.mkpath
    RESOURCE_FILES.grep(%r{/(app|support)/}).each do |file|
      cp tap_root/file, support/File.basename(file)
    end

    shell = buildpath/"libelectron/ohos_hap"
    project = buildpath/"claude-code-ohos-shell"
    ENV["CLAUDE_DESKTOP_APP_VERSION"] = version.to_s
    system "bash", res/"scripts/stage-ohos-shell.sh", shell, project

    # The HarmonyOS CLT is proprietary and is available to CI only through the
    # dedicated electron-ohos-ci image. Never put its signing credentials in a
    # bottle; end users sign locally through app-installer.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "claude-code-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['claude-code-app']"
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
    assembled_hap = buildpath/"claude-desktop-assembled-unsigned.hap"
    final_hap = buildpath/"claude-code-desktop-unsigned.hap"
    system "python3", support/"enable-cookie-encryption.py", shell_hap, encrypted_hap
    system "python3", support/"assemble-local-hap.py", encrypted_hap,
           stable.cached_download, assembled_hap
    system "python3", support/"patch-code-runtime-hap.py", assembled_hap,
           final_hap, "--no-host-config"

    libexec.install final_hap => "claude-code-desktop-unsigned.hap"
    pkgshare.mkpath
    cp res/"scripts/install-claude-code-desktop.sh", pkgshare/"install-desktop.sh"
    %w[
      patch-code-runtime-hap.py
      claude-bootstrap.cjs
      claude-code-platform-patch.cjs
      claude-launch-bridge.cjs
      claude-ohos-config.cjs
    ].each do |file|
      cp support/file, pkgshare/file
    end
    cp res/"scripts/claude-code-app.sh", libexec/"claude-code-app.sh"
    chmod 0755, [pkgshare/"install-desktop.sh", libexec/"claude-code-app.sh"]

    runtime_path = [
      formula_opt_bin("app-installer"),
      formula_opt_bin("claude-code.latest"),
      formula_opt_bin("node"),
      formula_opt_bin("python@3.15"),
      formula_opt_prefix("ohos-sdk-toolchains"),
      "$PATH",
    ].join(":")
    (bin/"claude-code-app").write_env_script libexec/"claude-code-app.sh",
      CLAUDE_CODE_APP_HDC:            formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      CLAUDE_CODE_APP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      CLAUDE_CODE_APP_UNSIGNED_HAP:   libexec/"claude-code-desktop-unsigned.hap",
      PATH:                           runtime_path
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "claude-code-app", "com.social4hyq.claudecode"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  def caveats
    <<~EOS
      `brew install`/`brew upgrade` installs the HAP automatically once the
      device and the Huawei Developer login are ready; otherwise it is queued:
      `hap-app status` shows why, `hap-app install-pending` finishes it.
      Manual: `claude-code-app install`. Details: docs/hap-app-formulae.md.

      The app needs the host `claude-code.latest` CLI installed and logged in;
      install injects the host paths into a private signed HAP, and ACL permissions
      let it spawn the CLI. `claude-code-app start` opens the app.
    EOS
  end

  test do
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    hap = libexec/"claude-code-desktop-unsigned.hap"
    assert_path_exists hap
    assert_match "Usage: claude-code-app", shell_output("#{bin}/claude-code-app --help")
    %w[
      patch-code-runtime-hap.py
      claude-bootstrap.cjs
      claude-code-platform-patch.cjs
      claude-launch-bridge.cjs
      claude-ohos-config.cjs
    ].each { |file| assert_path_exists pkgshare/file }
    assert_match "input_hap output_hap",
                 shell_output("python3 #{pkgshare}/patch-code-runtime-hap.py --help")

    test_sources = testpath/"claude-code-app-tests"
    test_sources.mkpath
    RESOURCE_FILES.grep(%r{/app/|/tests/}).each do |file|
      cp tap_root/file, test_sources/File.basename(file)
    end
    system "node", "--test", *test_sources.glob("*.test.cjs")

    module_json = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.claudecode", module_json.dig("app", "bundleName")
    assert_equal version.to_s, module_json.dig("app", "versionName")
    major, minor, patch = version.to_s.split(".").map(&:to_i)
    assert_equal (major << 22) | (minor << 8) | patch, module_json.dig("app", "versionCode")
    permissions = module_json.dig("module", "requestPermissions").map { |entry| entry.fetch("name") }
    assert_equal 7, permissions.length
    assert_includes permissions, "ohos.permission.CUSTOM_SANDBOX"
    assert_includes permissions, "ohos.permission.READ_WRITE_USER_FILE"
    assert_empty module_json.dig("module", "executableBinaryPaths") || []

    resource_strings = shell_output("unzip -p #{hap} resources.index | strings")
    assert_match "Claude Code", resource_strings
    refute_match "Claude PoC", resource_strings
    icon = testpath/"claude-icon.png"
    icon.write Utils.safe_popen_read("unzip", "-p", hap, "resources/base/media/app_icon.png")
    assert_equal "2188ade70c113978dbcc349468054dd948344a7b4497e2edac355b1b903c422d",
                 Digest::SHA256.file(icon).hexdigest

    listing = shell_output("unzip -l #{hap}")
    assert_match "resources/resfile/resources/app/vendor.asar", listing
    refute_match "claude-host-config.json", listing
    refute_match "claude-code-probe.bin", listing
    system "unzip", "-tq", hap
  end
end
