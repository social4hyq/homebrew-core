class BrunoDesktop < Formula
  desc "Bruno API client desktop shell for OpenHarmony/HarmonyOS PC"
  homepage "https://www.usebruno.com/"
  # The official arm64 Linux .deb is the pinned vendor payload (nounzip: the
  # package check selects the app.asar itself). Homebrew downloads it before
  # the build; the bottle ships only the tap-authored Electron-OHOS shell.
  url "https://github.com/usebruno/bruno/releases/download/v4.4.0/bruno_4.4.0_arm64_linux.deb",
      using: :nounzip
  sha256 "0264f6bd80deec178e89bdbe229e41747fa59e6fce1ef9bf9f3764924f362d7c"
  license "MIT"
  revision 4

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bruno-desktop-v4.4.0-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cdc4f0d449b4f2c6d6758ed1f72b1a0babcf6542a8f601f3d6635ba71f70d141"
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

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/enable-cookie-encryption.py
    Resources/bruno-desktop/app/bruno-bootstrap.cjs
    Resources/bruno-desktop/assets/icon.png
    Resources/bruno-desktop/scripts/stage-ohos-shell.sh
    Resources/bruno-desktop/support/assemble-local-hap.py
    Resources/bruno-desktop/tests/assemble-local-hap.test.py
    Resources/bruno-desktop/tests/bruno-bootstrap.test.cjs
  ].freeze

  def patch
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    super
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/bruno-desktop"
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

    libexec.install encrypted_hap => "bruno-desktop-unsigned.hap"
    (libexec/"vendor.json").write JSON.generate(
      "url"     => stable.url.to_s,
      "sha256"  => stable.checksum.hexdigest,
      "version" => version.to_s,
      "file"    => File.basename(stable.url.to_s),
    )

    pkgshare.mkpath
    assemble_dir = pkgshare/"assemble"
    assemble_dir.mkpath
    cp res/"support/assemble-local-hap.py", assemble_dir
    cp res/"app/bruno-bootstrap.cjs", assemble_dir

    # The ACL variant grants the weak-sandbox permissions used for host file
    # access. READ_PASTEBOARD is user_grant and needs a reason string in
    # module.json5, which would fail the build; add it to the overlay only.
    shell_module = JSON.parse(
      Utils.safe_popen_read("unzip", "-p", libexec/"bruno-desktop-unsigned.hap", "module.json"),
    )
    requested = shell_module.fetch("module").fetch("requestPermissions")
    unless requested.any? { |permission| permission["name"] == "ohos.permission.READ_PASTEBOARD" }
      requested << { "name" => "ohos.permission.READ_PASTEBOARD" }
    end
    (pkgshare/"module-acl.json").write JSON.generate(shell_module)

    # Validate the pinned vendor payload at build time: a release that changes
    # the app.asar layout must fail here.
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

    # The HAP is delivered through app.json; deployment is an explicit
    # `ohos-app install bruno-desktop`.
    (pkgshare/"ohos").mkpath
    hap = libexec/"bruno-desktop-unsigned.hap"
    hap_sha = Digest::SHA256.file(hap).hexdigest
    descriptor = {
      "schema_version" => 1,
      "id"             => "social4hyq/core/bruno-desktop",
      "artifact"       => {
        "format"       => "hap",
        "path"         => "../../../libexec/bruno-desktop-unsigned.hap",
        "sha256"       => hap_sha,
        "api"          => 12,
        "abis"         => ["arm64-v8a"],
        "bundle_id"    => "com.social4hyq.bruno",
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
    refute_path_exists bin/"bruno-app"

    hap = libexec/"bruno-desktop-unsigned.hap"
    vendor = JSON.parse((libexec/"vendor.json").read)
    assert_equal version.to_s, vendor.fetch("version")
    assert_match(/\A[0-9a-f]{64}\z/, vendor.fetch("sha256"))
    assert_match(%r{\Ahttps://}, vendor.fetch("url"))

    # Descriptor schema, id, digest and variants must match the HAP.
    descriptor = JSON.parse((pkgshare/"ohos/app.json").read)
    assert_equal 1, descriptor["schema_version"]
    assert_equal "social4hyq/core/bruno-desktop", descriptor["id"]
    assert_equal Digest::SHA256.file(hap).hexdigest, descriptor.dig("artifact", "sha256")
    assert_equal "com.social4hyq.bruno", descriptor.dig("artifact", "bundle_id")
    assert_equal "acl", descriptor.dig("variants", "default")
    assert_equal Digest::SHA256.file(pkgshare/"module-acl.json").hexdigest,
                 descriptor.dig("variants", "definitions", "acl", "sha256")

    module_json = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.bruno", module_json.dig("app", "bundleName")
    assert_equal version.to_s, module_json.dig("app", "versionName")
    permissions = module_json.dig("module", "requestPermissions").map { |item| item.fetch("name") }
    assert_includes permissions, "ohos.permission.CUSTOM_SANDBOX"
    assert_includes permissions, "ohos.permission.READ_WRITE_USER_FILE"
    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_permissions = acl.dig("module", "requestPermissions").map { |item| item.fetch("name") }
    assert_includes acl_permissions, "ohos.permission.CUSTOM_SANDBOX"
    # READ_PASTEBOARD is user_grant; the ACL variant carries it because a
    # reason string in module.json5 would fail the build.
    assert_includes acl_permissions, "ohos.permission.READ_PASTEBOARD"
    system "unzip", "-tq", hap

    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    system "python3", tap_root/"Resources/bruno-desktop/tests/assemble-local-hap.test.py"
    system "node", "--test", tap_root/"Resources/bruno-desktop/tests/bruno-bootstrap.test.cjs"
  end
end
