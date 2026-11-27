class BrewoDesktop < Formula
  desc "BrewUI-faithful Homebrew GUI for HarmonyOS PC, as a pure-ArkTS HAP"
  homepage "https://github.com/social4hyq/brewo-app"
  url "https://github.com/social4hyq/brewo-app/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "49d33aebf153347db7a2d8d80195f8b549d7696974304466ddebbaa1312aa16b"
  license "AGPL-3.0-only"
  revision 2

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/brewo-desktop-v0.3.2-r1"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "13d6c0b358c08fff310233f8d6010402d0de45810a404c22ba0f9341246db5d4"
  end

  depends_on "node" => :build
  depends_on "ohos-sdk" => :build
  depends_on "zip" => :build
  depends_on "harbor-desktop"
  depends_on "python@3.15"

  def install
    clt = Pathname("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "#{name} builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['#{name}']"
    end

    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] = "#{clt}/lib:" \
                             "#{clt}/sdk/default/openharmony/native/llvm/lib/" \
                             "clang/15.0.4/lib/aarch64-linux-ohos"

    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    system "node", clt/"ohpm/bin/pm-cli.js", "install"
    system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
           "--mode", "module", "-p", "product=default", "--no-daemon"

    # Compile the native NAPI bridge with the OHOS clang and inject into the HAP.
    llvm = formula_opt_prefix("ohos-sdk")/"native/llvm/bin"
    sysroot = formula_opt_prefix("ohos-sdk")/"native/sysroot"
    (buildpath/"entry/src/main/cpp/libs/arm64-v8a").mkpath
    system llvm/"clang", "--target=aarch64-unknown-linux-ohos", "--sysroot=#{sysroot}",
           "-fPIC", "-shared", "-O2",
           "-I#{sysroot}/usr/include/napi", "-I#{sysroot}/usr/include",
           "entry/src/main/cpp/brewo_bridge.c",
           "-L#{sysroot}/usr/lib/aarch64-linux-ohos", "-lace_napi.z", "-Wl,-z,global",
           "-o", "entry/src/main/cpp/libs/arm64-v8a/libbrewo_bridge.so"

    hap = Pathname("entry/build/default/outputs/default/entry-default-unsigned.hap").expand_path
    stage = Pathname("so-stage")
    (stage/"libs/arm64-v8a").mkpath
    cp "entry/src/main/cpp/libs/arm64-v8a/libbrewo_bridge.so", stage/"libs/arm64-v8a/"
    Dir.chdir(stage) { system "zip", "-q", "-r", hap.to_s, "libs" }
    hap_entries = Utils.safe_popen_read("unzip", "-l", hap.to_s)
    odie "native bridge missing from HAP" unless hap_entries.include?("libbrewo_bridge.so")

    libexec.install hap => "brewo-desktop-unsigned.hap"
    libexec.install "scripts/brewo-host.py"
    (bin/"brewo-host").write_env_script formula_opt_bin("python@3.15")/"python3.15",
                                        [opt_libexec/"brewo-host.py"], {}

    # Assert the HAP declares the permissions Brewo needs.
    module_json = JSON.parse(
      Utils.safe_popen_read("unzip", "-p", libexec/"brewo-desktop-unsigned.hap", "module.json"),
    )
    requested = module_json.fetch("module").fetch("requestPermissions").map { |p| p["name"] }
    %w[ohos.permission.INTERNET ohos.permission.CUSTOM_SANDBOX
       ohos.permission.READ_WRITE_USER_FILE].each do |perm|
      odie "missing permission in HAP: #{perm}" unless requested.include?(perm)
    end

    # The HAP is delivered through app.json; deployment is an explicit
    # `ohos-app install brewo-desktop`. The host bridge ships separately.
    # Descriptor is written at build time with the real HAP digest and version.
    (pkgshare/"ohos").mkpath
    hap = libexec/"brewo-desktop-unsigned.hap"
    hap_sha = Digest::SHA256.file(hap).hexdigest
    descriptor = {
      "schema_version" => 1,
      "id"             => "social4hyq/core/brewo-desktop",
      "artifact"       => {
        "format"       => "hap",
        "path"         => "../../../libexec/brewo-desktop-unsigned.hap",
        "sha256"       => hap_sha,
        "api"          => 12,
        "abis"         => ["arm64-v8a"],
        "bundle_id"    => "com.social4hyq.brewo",
        "version_name" => version.to_s,
        "version_code" => 1,
      },
      "launch"         => { "module" => "entry", "ability" => "EntryAbility" },
      "variants"       => {
        "default"     => "basic",
        "definitions" => { "basic" => {} },
      },
    }
    (pkgshare/"ohos/app.json").write JSON.pretty_generate(descriptor) + "\n"
  end

  test do
    # Only the HAP, descriptor and the host bridge are delivered.
    refute_path_exists bin/"brewo-app"

    # brewo-host is the delivered host bridge, not the removed installer CLI.
    assert_match "--register-harbor", shell_output("#{bin}/brewo-host --help")

    # Descriptor schema, id and digest must match the HAP.
    descriptor = JSON.parse((pkgshare/"ohos/app.json").read)
    assert_equal 1, descriptor["schema_version"]
    assert_equal "social4hyq/core/brewo-desktop", descriptor["id"]
    hap = libexec/"brewo-desktop-unsigned.hap"
    assert_equal Digest::SHA256.file(hap).hexdigest, descriptor.dig("artifact", "sha256")
    assert_equal "com.social4hyq.brewo", descriptor.dig("artifact", "bundle_id")
    assert_equal "basic", descriptor.dig("variants", "default")

    assert_path_exists hap
    module_json = JSON.parse(Utils.safe_popen_read("unzip", "-p", hap, "module.json"))
    assert_equal "com.social4hyq.brewo", module_json.dig("app", "bundleName")
  end
end
