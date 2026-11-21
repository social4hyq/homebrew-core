class ClaudeCodeApp < Formula
  desc "Claude Code Desktop shell for OpenHarmony/HarmonyOS PC"
  homepage "https://code.claude.com/docs/en/desktop-linux"
  url "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_6.28899.2_arm64.deb",
      using: :nounzip
  version "6.28899.2"
  sha256 "7ec2a354ecb8bafae3e3ccafe620144232b7429b216ab59a05a0d6cc340f1455"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 2

  livecheck do
    url "https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-arm64/Packages"
    regex(%r{^Filename: pool/main/c/claude-desktop/claude-desktop_(\d+(?:\.\d+)+)_arm64\.deb$}i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-app-v6.28899.2-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4a467ee4a5256cea2e4240fa385ce441f7d69e72bc75a49af49ee305b1e5daef"
  end

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

  # The unused-resource audit requires literal tap paths.
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
    Resources/_shared/hap-app/enable-cookie-encryption.py
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
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }
    support = buildpath/"claude-code-support"
    support.mkpath
    RESOURCE_FILES.grep(%r{/(app|support|hap-app)/}).each do |file|
      cp tap_root/file, support/File.basename(file)
    end

    shell = buildpath/"libelectron/ohos_hap"
    project = buildpath/"claude-code-ohos-shell"
    ENV["CLAUDE_DESKTOP_APP_VERSION"] = version.to_s
    system "bash", res/"scripts/stage-ohos-shell.sh", shell, project

    # The HarmonyOS CLT is proprietary and CI-only; never put signing
    # credentials in a bottle (users sign locally via app-installer).
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
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd project do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    shell_hap = project/"electron/build/default/outputs/default/electron-default-unsigned.hap"
    encrypted_hap = buildpath/"electron-default-cookie-unsigned.hap"
    system "python3", support/"enable-cookie-encryption.py", shell_hap, encrypted_hap

    # The bottle ships only this tap-authored shell; `claude-code-app install`
    # downloads Anthropic's official package and assembles the HAP locally, so
    # the tap does not redistribute Anthropic binaries.
    libexec.install encrypted_hap => "claude-code-shell-unsigned.hap"
    (libexec/"vendor.json").write JSON.generate(
      "url"     => stable.url.to_s,
      "sha256"  => stable.checksum.hexdigest,
      "version" => version.to_s,
      "file"    => File.basename(stable.url.to_s),
    )
    pkgshare.mkpath
    cp res/"scripts/install-claude-code-desktop.sh", pkgshare/"install-desktop.sh"
    cp support/"assemble-local-hap.py", pkgshare/"assemble-local-hap.py"
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
      CLAUDE_CODE_APP_UNSIGNED_HAP:   libexec/"claude-code-shell-unsigned.hap",
      CLAUDE_CODE_APP_VENDOR_JSON:    libexec/"vendor.json",
      CLAUDE_CODE_APP_ASSEMBLER:      pkgshare/"assemble-local-hap.py",
      PATH:                           runtime_path
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "claude-code-app", "com.social4hyq.claudecode"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  def caveats
    <<~EOS
      `brew install` and `brew upgrade` try to install the HAP when a device is
      connected and Huawei Developer login is ready. If queued, check
      `hap-app status`, then run `hap-app install-pending`.
      Manual install: `claude-code-app install`. See docs/hap-app-formulae.md.

      The bottle ships only the tap-authored shell; the first install asks
      Anthropic for the official package (sha256-checked) and caches it in
      ~/.cache/claude-code-app/vendor/. Use `claude-code-app install --deb PATH`
      for an offline copy, and `--clean-cache` to remove the cached package.

      The app needs the host `claude-code.latest` CLI installed and logged in;
      install injects the host paths into a private signed HAP, and ACL permissions
      let it spawn the CLI. `claude-code-app start` opens the app.
    EOS
  end

  test do
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    hap = libexec/"claude-code-shell-unsigned.hap"
    vendor = JSON.parse((libexec/"vendor.json").read)
    assert_equal version.to_s, vendor.fetch("version")
    assert_match(/\A[0-9a-f]{64}\z/, vendor.fetch("sha256"))
    assert_match(%r{\Ahttps://}, vendor.fetch("url"))
    system "python3", pkgshare/"assemble-local-hap.py", "--help"
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
    assert_equal (major << 25) | (minor << 8) | patch, module_json.dig("app", "versionCode")
    permissions = module_json.dig("module", "requestPermissions").map { |entry| entry.fetch("name") }
    assert_includes permissions, "ohos.permission.INTERNET"
    refute_includes permissions, "ohos.permission.CUSTOM_SANDBOX"
    assert_empty module_json.dig("module", "executableBinaryPaths") || []

    resource_strings = shell_output("unzip -p #{hap} resources.index | strings")
    assert_match "Claude Code", resource_strings
    refute_match "Claude PoC", resource_strings
    icon = testpath/"claude-icon.png"
    icon.write Utils.safe_popen_read("unzip", "-p", hap, "resources/base/media/app_icon.png")
    assert_equal "2188ade70c113978dbcc349468054dd948344a7b4497e2edac355b1b903c422d",
                 Digest::SHA256.file(icon).hexdigest

    listing = shell_output("unzip -l #{hap}")
    refute_match "vendor.asar", listing
    refute_match "ion-dist.asar", listing
    refute_match "claude-host-config.json", listing
    refute_match "claude-code-probe.bin", listing
    system "unzip", "-tq", hap
  end
end
