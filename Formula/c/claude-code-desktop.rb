class ClaudeCodeDesktop < Formula
  desc "Desktop shell for Claude Code on OpenHarmony/HarmonyOS PC"
  homepage "https://code.claude.com/docs/en/desktop-linux"
  url "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_6.28899.6_arm64.deb",
      using: :nounzip
  version "6.28899.6"
  sha256 "239c20d218456cacc656d48382fd59116325ac679aa4e476377af1456ac85715"
  license :cannot_represent # Anthropic Legal Agreements (Commercial ToS)
  revision 9

  livecheck do
    url "https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-arm64/Packages"
    regex(%r{^Filename: pool/main/c/claude-desktop/claude-desktop_(\d+(?:\.\d+)+)_arm64\.deb$}i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/claude-code-desktop-v6.28899.6-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "74a638e03a5865b008643b8c816cccfa374f1b2b91827d1416a83d1f0ca3e173"
  end

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
  Dir[(patch_root/"Patches/claude-code-desktop/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
      directory "libelectron/ohos_hap"
    end
  end

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/claude-code-desktop/assets/icon.png
    Resources/claude-code-desktop/scripts/stage-ohos-shell.sh
    Resources/claude-code-desktop/app/claude-bootstrap.cjs
    Resources/claude-code-desktop/app/claude-code-platform-patch.cjs
    Resources/claude-code-desktop/app/claude-launch-bridge.cjs
    Resources/claude-code-desktop/app/claude-ohos-config.cjs
    Resources/_shared/hap-app/enable-cookie-encryption.py
    Resources/claude-code-desktop/tests/claude-bootstrap.test.cjs
    Resources/claude-code-desktop/tests/close-handler.test.cjs
    Resources/claude-code-desktop/tests/claude-code-platform-patch.test.cjs
    Resources/claude-code-desktop/tests/claude-launch-bridge.test.cjs
    Resources/claude-code-desktop/tests/claude-ohos-config.test.cjs
  ].freeze

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    super
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/claude-code-desktop"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }
    support = buildpath/"claude-code-support"
    support.mkpath
    RESOURCE_FILES.grep(%r{/(app|hap-app)/}).each do |file|
      cp tap_root/file, support/File.basename(file)
    end

    shell = buildpath/"libelectron/ohos_hap"
    project = buildpath/"claude-code-ohos-shell"
    ENV["CLAUDE_DESKTOP_APP_VERSION"] = version.to_s
    system "bash", res/"scripts/stage-ohos-shell.sh", shell, project

    # The HarmonyOS CLT is proprietary and CI-only; never put signing
    # credentials in a bottle.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "#{name} builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['#{name}']"
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

    libexec.install encrypted_hap => "claude-code-desktop-unsigned.hap"

    # The HAP is delivered through app.json; deployment is an explicit
    # `ohos-app install claude-code-desktop`. The upstream CLI stays independent.
    (pkgshare/"ohos").mkpath
    hap = libexec/"claude-code-desktop-unsigned.hap"
    hap_sha = Digest::SHA256.file(hap).hexdigest
    descriptor = {
      "schema_version" => 1,
      "id"             => "social4hyq/core/claude-code-desktop",
      "artifact"       => {
        "format"       => "hap",
        "path"         => "../../../libexec/claude-code-desktop-unsigned.hap",
        "sha256"       => hap_sha,
        "api"          => 12,
        "abis"         => ["arm64-v8a"],
        "bundle_id"    => "com.social4hyq.claudecode",
        "version_name" => version.to_s,
        "version_code" => 1,
      },
      "launch"         => { "module" => "electron", "ability" => "EntryAbility" },
      "variants"       => { "default" => "basic", "definitions" => { "basic" => {} } },
    }
    (pkgshare/"ohos/app.json").write JSON.pretty_generate(descriptor) + "\n"
  end

  test do
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    # Only the HAP and descriptor are delivered; no app-level install command.
    refute_path_exists bin/"claude-code-app"

    descriptor = JSON.parse((pkgshare/"ohos/app.json").read)
    assert_equal 1, descriptor["schema_version"]
    assert_equal "social4hyq/core/claude-code-desktop", descriptor["id"]
    hap = libexec/"claude-code-desktop-unsigned.hap"
    assert_equal Digest::SHA256.file(hap).hexdigest, descriptor.dig("artifact", "sha256")
    assert_equal "com.social4hyq.claudecode", descriptor.dig("artifact", "bundle_id")
    assert_equal "basic", descriptor.dig("variants", "default")

    test_sources = testpath/"claude-code-desktop-tests"
    test_sources.mkpath
    RESOURCE_FILES.grep(%r{/app/|/tests/}).each do |file|
      cp tap_root/file, test_sources/File.basename(file)
    end
    # The tests are copied flat; the close handler test needs the staging script itself.
    with_env("CLAUDE_STAGE_SCRIPT" => (tap_root/"Resources/claude-code-desktop/scripts/stage-ohos-shell.sh").to_s) do
      system "node", "--test", *test_sources.glob("*.test.cjs")
    end

    module_json = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.claudecode", module_json.dig("app", "bundleName")
    assert_equal version.to_s, module_json.dig("app", "versionName")
    major, minor, patch = version.to_s.split(".").map(&:to_i)
    assert_equal (major << 25) | (minor << 8) | patch, module_json.dig("app", "versionCode")
    permissions = module_json.dig("module", "requestPermissions").map { |entry| entry.fetch("name") }
    assert_includes permissions, "ohos.permission.INTERNET"
    assert_includes permissions, "ohos.permission.MICROPHONE"
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
