class CodexDesktop < Formula
  desc "ChatGPT desktop shell for OpenHarmony/HarmonyOS PC"
  homepage "https://learn.chatgpt.com/docs/linux/linux-app"
  url "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_26.1120.50957_arm64.deb",
      using: :nounzip
  version "26.1120.50957"
  sha256 "d11adb9a13d21bc5f514885924207af0e8689a978328550e3a43895a69603d89"
  license :cannot_represent # OpenAI service and software terms
  revision 3

  livecheck do
    url "https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-arm64/Packages"
    regex(%r{^Filename: pool/main/c/chatgpt/chatgpt_(\d+(?:\.\d+)+)_arm64\.deb$}i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/codex-desktop-v26.1120.50957-r4"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "daedad12903341f5a3d2a15977bd74ef69996769325e7e3032f87edfdbe96384"
  end

  depends_on "ohos-hap-clt" => :build
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

  # Publicly mirrored official CLT replaces the private electron-ohos-ci image.
  resource "command-line-tools" do
    url "https://s3.oheco.org/command-line-tools/26.0.0.201/commandline-tools-harmonyos-26.0.0.201.tar.gz"
    sha256 "60929c00ae486cc038ea48145497ad34dbd4ac6a25c3f2fa895ce74afb4607f5"
  end

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/codex-desktop/assets/icon.png
    Resources/codex-desktop/app/chatgpt-bootstrap.cjs
    Resources/codex-desktop/app/owl-codex-bridge.cjs
    Resources/codex-desktop/app/owl-compat.cjs
    Resources/codex-desktop/app/owl-host-shim.cjs
    Resources/codex-desktop/app/owl-pty-host.cjs
    Resources/codex-desktop/app/owl-pty-shim.cjs
    Resources/codex-desktop/app/owl-share.cjs
    Resources/codex-desktop/app/owl-sqlite-shim.cjs
    Resources/codex-desktop/app/owl-tray.cjs
    Resources/codex-desktop/app/owl-utility-entry.cjs
    Resources/codex-desktop/app/tray-icon.png
    Resources/codex-desktop/scripts/stage-ohos-shell.sh
    Resources/codex-desktop/support/assemble-local-hap.py
    Resources/codex-desktop/tests/assemble-local-hap.test.py
    Resources/codex-desktop/tests/chatgpt-bootstrap.test.cjs
    Resources/codex-desktop/tests/close-handler.test.cjs
    Resources/codex-desktop/tests/owl-share.test.cjs
    Resources/codex-desktop/tests/owl-tray.test.cjs
    Resources/_shared/hap-app/enable-cookie-encryption.py
  ].freeze

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    super
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/codex-desktop"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    support = buildpath/"codex-desktop-support"
    support.mkpath
    RESOURCE_FILES.grep(%r{/app/|/support/}).each do |file|
      cp tap_root/file, support/File.basename(file)
    end
    cp tap_root/"Resources/_shared/hap-app/enable-cookie-encryption.py", support

    shell = buildpath/"libelectron/ohos_hap"
    project = buildpath/"chatgpt-ohos-shell"
    system "bash", res/"scripts/stage-ohos-shell.sh", shell, project, version.to_s

    # Electron HAP tooling is proprietary and comes from the CI image; signing
    # stays a local user action.
    # Stage the publicly mirrored CLI into the build tree: no private image.
    clt = buildpath/"command-line-tools"
    hap_clt = formula_opt_bin("ohos-hap-clt")/"ohos-hap-clt"
    archive = resource("command-line-tools")
    archive.fetch
    system hap_clt.to_s, "stage", clt.to_s, archive.cached_download.to_s

    # ohpm and ohos_packing_tool need the staged SDK libraries on the search
    # path; the hvigor wrapper extends this same value for the assemble step.
    clang_lib = (clt/"sdk/default/openharmony/native/llvm/lib").glob("clang/*/lib/aarch64-linux-ohos").first
    odie "staged CLT missing clang runtime" if clang_lib.nil?
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] = "#{clt}/lib:#{clang_lib}"
    ENV.delete("NODE_OPTIONS")
    # The hvigor wrapper patches OHOS Node detection and HiLog logging that
    # were previously baked into the private image.
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd project do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system hap_clt.to_s, "hvigor", clt.to_s, "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    shell_hap = project/"electron/build/default/outputs/default/electron-default-unsigned.hap"
    encrypted_hap = buildpath/"electron-default-cookie-unsigned.hap"
    system "python3", support/"enable-cookie-encryption.py", shell_hap, encrypted_hap

    libexec.install encrypted_hap => "codex-desktop-unsigned.hap"
    pkgshare.mkpath
    module_json = JSON.parse(
      Utils.safe_popen_read("unzip", "-p", libexec/"codex-desktop-unsigned.hap", "module.json"),
    )
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.READ_PASTEBOARD ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # The HAP is delivered through app.json; deployment is an explicit
    # `ohos-app install codex-desktop`. The upstream CLI stays independent.
    (pkgshare/"ohos").mkpath
    hap = libexec/"codex-desktop-unsigned.hap"
    hap_sha = Digest::SHA256.file(hap).hexdigest
    descriptor = {
      "schema_version" => 1,
      "id"             => "social4hyq/core/codex-desktop",
      "artifact"       => {
        "format"       => "hap",
        "path"         => "../../../libexec/codex-desktop-unsigned.hap",
        "sha256"       => hap_sha,
        "api"          => 12,
        "abis"         => ["arm64-v8a"],
        "bundle_id"    => "com.social4hyq.chatgpt",
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
    refute_path_exists bin/"codex-app"

    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    descriptor = JSON.parse((pkgshare/"ohos/app.json").read)
    assert_equal 1, descriptor["schema_version"]
    assert_equal "social4hyq/core/codex-desktop", descriptor["id"]
    hap = libexec/"codex-desktop-unsigned.hap"
    assert_equal Digest::SHA256.file(hap).hexdigest, descriptor.dig("artifact", "sha256")
    assert_equal "com.social4hyq.chatgpt", descriptor.dig("artifact", "bundle_id")
    assert_equal version.to_s, descriptor.dig("artifact", "version_name")
    assert_equal "acl", descriptor.dig("variants", "default")
    assert_equal Digest::SHA256.file(pkgshare/"module-acl.json").hexdigest,
                 descriptor.dig("variants", "definitions", "acl", "sha256")

    system "node", "--check", tap_root/"Resources/codex-desktop/app/chatgpt-bootstrap.cjs"
    owl_shims = %w[owl-codex-bridge owl-compat owl-host-shim owl-pty-host owl-pty-shim owl-share owl-sqlite-shim
                   owl-tray owl-utility-entry]
    owl_shims.each do |name|
      system "node", "--check", tap_root/"Resources/codex-desktop/app/#{name}.cjs"
    end
    system "node", "--test", tap_root/"Resources/codex-desktop/tests/chatgpt-bootstrap.test.cjs"
    system "node", "--test", tap_root/"Resources/codex-desktop/tests/owl-share.test.cjs"
    system "node", "--test", tap_root/"Resources/codex-desktop/tests/owl-tray.test.cjs"
    system "node", "--test", tap_root/"Resources/codex-desktop/tests/close-handler.test.cjs"
    system "python3", tap_root/"Resources/codex-desktop/tests/assemble-local-hap.test.py"

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
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each { |name| assert_includes acl_permissions, name }
    listing = shell_output("unzip -Z1 #{hap}")
    refute_match "vendor.asar", listing
    refute_match "resources/resfile/resources/codex", listing
    refute_match "vendor.asar.unpacked", listing
    owl_shims.each do |name|
      refute_match "resources/resfile/resources/app/#{name}.cjs", listing
    end
    icon = testpath/"shell-icon.png"
    icon.write Utils.safe_popen_read("unzip", "-p", hap, "resources/base/media/app_icon.png")
    assert_equal Digest::SHA256.file(tap_root/"Resources/codex-desktop/assets/icon.png").hexdigest,
                 Digest::SHA256.file(icon).hexdigest
    system "unzip", "-tq", hap
  end
end
