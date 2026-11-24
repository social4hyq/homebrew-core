class HarborApp < Formula
  desc "Systemd-like service manager for HarmonyOS PC, as a tiny pure-ArkTS HAP"
  homepage "https://github.com/social4hyq/harbor-app"
  url "https://github.com/social4hyq/harbor-app/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "809b8fd7ce35846dc843485b39b2db41e4031c0da76ca4cca9068bac1e29cb35"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/harbor-app-v0.1.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0000000000000000000000000000000000000000000000000000000000000000"
  end

  depends_on "node" => :build
  depends_on "ohos-sdk" => :build
  depends_on "zip" => :build
  depends_on "app-installer"
  depends_on "python@3.15"

  def install
    clt = Pathname("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "harbor-app needs the electron-ohos CI image (hvigor at " \
           "#{clt}/hvigor/bin/hvigorw.js); add harbor-app to the " \
           "OHOS_CI_IMAGE_OVERRIDES repo variable"
    end

    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] = "#{clt}/lib:" \
                             "#{clt}/sdk/default/openharmony/native/llvm/lib/" \
                             "clang/15.0.4/lib/aarch64-linux-ohos"

    # Limit RLIMIT_NOFILE (oversized values break the musl FD table in hvigor).
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
           "entry/src/main/cpp/harbor_bridge.c",
           "-L#{sysroot}/usr/lib/aarch64-linux-ohos", "-lace_napi.z", "-Wl,-z,global",
           "-o", "entry/src/main/cpp/libs/arm64-v8a/libharbor_bridge.so"

    hap = Pathname("entry/build/default/outputs/default/entry-default-unsigned.hap").expand_path
    stage = Pathname("so-stage")
    (stage/"libs/arm64-v8a").mkpath
    cp "entry/src/main/cpp/libs/arm64-v8a/libharbor_bridge.so", stage/"libs/arm64-v8a/"
    Dir.chdir(stage) { system "zip", "-q", "-r", hap.to_s, "libs" }
    hap_entries = Utils.safe_popen_read("unzip", "-l", hap.to_s)
    odie "native bridge missing from HAP" unless hap_entries.include?("libharbor_bridge.so")

    libexec.install hap => "harbor-unsigned.hap"
    bin.install "harbor"
    (pkgshare/"apps.json.default").write <<~JSON
      {
        "autoHideOnLaunch": true,
        "apps": []
      }
    JSON

    # Assert the HAP declares the ACL permissions Harbor needs.
    module_json = JSON.parse(Utils.safe_popen_read("unzip", "-p", libexec/"harbor-unsigned.hap", "module.json"))
    requested = module_json.fetch("module").fetch("requestPermissions").map { |p| p["name"] }
    %w[ohos.permission.INTERNET ohos.permission.CUSTOM_SANDBOX
       ohos.permission.READ_WRITE_USER_FILE ohos.permission.KEEP_BACKGROUND_RUNNING].each do |perm|
      odie "missing permission in HAP: #{perm}" unless requested.include?(perm)
    end
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "harbor", "org.social4hyq.harbor"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    help = shell_output("#{bin}/harbor --help")
    assert_match "brew services", help
    assert_match "discover", help
    assert_path_exists libexec/"harbor-unsigned.hap"
    assert_path_exists pkgshare/"apps.json.default"
    module_json = JSON.parse(Utils.safe_popen_read("unzip", "-p", libexec/"harbor-unsigned.hap", "module.json"))
    assert_equal "org.social4hyq.harbor", module_json.dig("app", "bundleName")
  end
end
