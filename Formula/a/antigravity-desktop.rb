class AntigravityDesktop < Formula
  desc "Google Antigravity desktop shell for OpenHarmony/HarmonyOS PC"
  homepage "https://antigravity.google/download"
  url "https://storage.googleapis.com/antigravity-public/antigravity-hub/" \
      "2.34.0-5887025308631040/linux-arm/Antigravity.tar.gz"
  sha256 "91f31ce50c795e0571e7922511119ff3e7afc2ee4f640a97d69dbad2063c1866"
  license :cannot_represent # Google Terms of Service; closed-source prebuilt desktop app
  revision 12

  livecheck do
    url :homepage
    regex(%r{antigravity-hub/(\d+(?:\.\d+)+)-\d+}i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/antigravity-desktop-v2.34.0-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "eb0040250630dfcbb94e87d209d4ebec7494133672a311471a37241aa11b03f8"
  end

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

  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/enable-cookie-encryption.py
    Resources/antigravity-desktop/app/antigravity-bootstrap.cjs
    Resources/antigravity-desktop/assets/icon.png
    Resources/antigravity-desktop/scripts/stage-ohos-shell.sh
    Resources/antigravity-desktop/support/assemble-local-hap.py
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
    project = buildpath/"antigravity-ohos-shell"
    system "bash", tap_root/"Resources/antigravity-desktop/scripts/stage-ohos-shell.sh",
           shell, project, version.to_s

    # The proprietary CLT is supplied by the CI image, not distributed by the tap.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "#{name} builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['#{name}']"
    end

    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    # An oversized RLIMIT_NOFILE breaks the musl FD table in hvigor.
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

    hap = libexec/"antigravity-desktop-unsigned.hap"
    libexec.install encrypted_hap => "antigravity-desktop-unsigned.hap"
    (libexec/"vendor.json").write JSON.generate(
      "url"     => stable.url.to_s,
      "sha256"  => stable.checksum.hexdigest,
      "version" => version.to_s,
      "file"    => "Antigravity.tar.gz",
    )

    # Fail the build if the pinned vendor package no longer carries the engine
    # the shell connects to.
    verify_script = tap_root/"Resources/antigravity-desktop/support/assemble-local-hap.py"
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
      Utils.safe_popen_read("unzip", "-p", hap, "module.json"),
    )
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # The HAP is delivered through app.json; deployment is an explicit
    # `ohos-app install antigravity-desktop`. The upstream CLI stays independent.
    # Descriptor is written at build time with the real HAP digest and version.
    (pkgshare/"ohos").mkpath
    hap_sha = Digest::SHA256.file(hap).hexdigest
    descriptor = {
      "schema_version" => 1,
      "id"             => "social4hyq/core/antigravity-desktop",
      "artifact"       => {
        "format"       => "hap",
        "path"         => "../../../libexec/antigravity-desktop-unsigned.hap",
        "sha256"       => hap_sha,
        "api"          => 12,
        "abis"         => ["arm64-v8a"],
        "bundle_id"    => "com.social4hyq.antigravity",
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
    refute_path_exists bin/"antigravity-app"

    vendor = JSON.parse((libexec/"vendor.json").read)
    assert_equal version.to_s, vendor.fetch("version")
    assert_match(/\A[0-9a-f]{64}\z/, vendor.fetch("sha256"))
    assert_match "https://", vendor.fetch("url")

    descriptor = JSON.parse((pkgshare/"ohos/app.json").read)
    assert_equal 1, descriptor["schema_version"]
    assert_equal "social4hyq/core/antigravity-desktop", descriptor["id"]
    hap = libexec/"antigravity-desktop-unsigned.hap"
    assert_equal Digest::SHA256.file(hap).hexdigest, descriptor.dig("artifact", "sha256")
    assert_equal "com.social4hyq.antigravity", descriptor.dig("artifact", "bundle_id")
    assert_equal "acl", descriptor.dig("variants", "default")
    assert_equal Digest::SHA256.file(pkgshare/"module-acl.json").hexdigest,
                 descriptor.dig("variants", "definitions", "acl", "sha256")

    listing = shell_output("unzip -Z1 #{hap}")
    assert_includes listing, "resources/resfile/resources/app/antigravity-bootstrap.cjs"
    package = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/package.json"))
    assert_equal version.to_s, package["version"]
    assert_equal "antigravity-bootstrap.cjs", package["main"]
    module_json = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "com.social4hyq.antigravity", module_json.dig("app", "bundleName")
  end
end
