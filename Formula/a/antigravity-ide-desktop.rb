class AntigravityIdeDesktop < Formula
  desc "Google Antigravity IDE shell for OpenHarmony/HarmonyOS PC"
  homepage "https://antigravity.google/download"
  url "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/" \
      "2.8.0-6733682917113856/linux-arm/Antigravity%20IDE.tar.gz"
  sha256 "d8f85ce40306587a80a7478af4de85cb10b83cf26dd9179b902afa9933fcf9f2"
  license :cannot_represent # Google Terms of Service; closed-source prebuilt desktop app
  revision 11

  livecheck do
    url :homepage
    regex(%r{antigravity/stable/(\d+(?:\.\d+)+)-\d+}i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/antigravity-ide-desktop-v2.8.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "37f8e528a32a68a2ab2a6fada48716c73be2d7bf40b0c91749008084919b4cdc"
  end

  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "python@3.15"
  depends_on "unzip"
  depends_on "zip"

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  # The HAP shell is built from the electron-ohos template and tap-authored
  # resources; the proprietary IDE engine is not distributed in the bottle.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/enable-cookie-encryption.py
    Resources/antigravity-ide-desktop/app/antigravity-ide-app-bootstrap.cjs
    Resources/antigravity-ide-desktop/assets/icon.png
    Resources/antigravity-ide-desktop/scripts/stage-ohos-shell.sh
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

    shell = buildpath/"libelectron/ohos_hap"
    project = buildpath/"antigravity-ide-desktop-ohos-shell"
    system "bash", tap_root/"Resources/antigravity-ide-desktop/scripts/stage-ohos-shell.sh",
           shell, project, version.to_s

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
    system "python3", tap_root/"Resources/_shared/hap-app/enable-cookie-encryption.py",
           shell_hap, encrypted_hap

    libexec.install encrypted_hap => "antigravity-ide-desktop-unsigned.hap"

    pkgshare.mkpath
    module_json = JSON.parse(
      Utils.safe_popen_read("unzip", "-p", libexec/"antigravity-ide-desktop-unsigned.hap", "module.json"),
    )
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |permission|
      requested << { "name" => permission } unless requested.any? { |entry| entry["name"] == permission }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # The HAP is delivered through app.json; deployment is an explicit
    # `ohos-app install antigravity-ide-desktop`.
    (pkgshare/"ohos").mkpath
    hap = libexec/"antigravity-ide-desktop-unsigned.hap"
    hap_sha = Digest::SHA256.file(hap).hexdigest
    descriptor = {
      "schema_version" => 1,
      "id"             => "social4hyq/core/antigravity-ide-desktop",
      "artifact"       => {
        "format"       => "hap",
        "path"         => "../../libexec/antigravity-ide-desktop-unsigned.hap",
        "sha256"       => hap_sha,
        "api"          => 12,
        "abis"         => ["arm64-v8a"],
        "bundle_id"    => "com.social4hyq.antigravityide",
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
    refute_path_exists bin/"antigravity-ide-app"

    descriptor = JSON.parse((pkgshare/"ohos/app.json").read)
    assert_equal 1, descriptor["schema_version"]
    assert_equal "social4hyq/core/antigravity-ide-desktop", descriptor["id"]
    hap = libexec/"antigravity-ide-desktop-unsigned.hap"
    assert_equal Digest::SHA256.file(hap).hexdigest, descriptor.dig("artifact", "sha256")
    assert_equal "com.social4hyq.antigravityide", descriptor.dig("artifact", "bundle_id")
    assert_equal "electron", descriptor.dig("launch", "module")
    assert_equal "EntryAbility", descriptor.dig("launch", "ability")
    assert_equal "acl", descriptor.dig("variants", "default")
    assert_equal Digest::SHA256.file(pkgshare/"module-acl.json").hexdigest,
                 descriptor.dig("variants", "definitions", "acl", "sha256")

    listing = shell_output("unzip -l #{hap}")
    assert_match "resources/resfile/resources/app/antigravity-ide-app-bootstrap.cjs", listing
    package = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/package.json"))
    assert_equal version.to_s, package["version"]
    assert_includes listing, "resources/resfile/resources/app/#{package.fetch("main")}"

    module_json = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET],
                 module_json.dig("module", "requestPermissions").map { |permission| permission["name"] }.sort
    acl_module = JSON.parse((pkgshare/"module-acl.json").read)
    acl_permissions = acl_module.dig("module", "requestPermissions").map { |permission| permission["name"] }
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |permission|
      assert_includes acl_permissions, permission
    end
  end
end
