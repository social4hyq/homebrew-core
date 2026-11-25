class CellarApp < Formula
  desc "Homebrew GUI for HarmonyOS PC, a BrewUI-faithful pure-ArkTS HAP"
  homepage "https://github.com/social4hyq/cellar-app"
  url "https://github.com/social4hyq/cellar-app/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "2235d1bcfef422fd9e974901052f87de678e1b5d59a93ad3a7abf1f72c67a616"
  license "AGPL-3.0-only"
  revision 1

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/cellar-app-v0.1.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "64f01d4c4fd356c09a190ae3bcfafd353278b28fc7c3544fa01e483328084fce"
  end

  depends_on "node" => :build
  depends_on "ohos-sdk" => :build
  depends_on "zip" => :build
  depends_on "app-installer"
  depends_on "python@3.15"

  def install
    clt = Pathname("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "cellar-app needs the electron-ohos CI image (hvigor at " \
           "#{clt}/hvigor/bin/hvigorw.js); add cellar-app to the " \
           "OHOS_CI_IMAGE_OVERRIDES repo variable"
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
           "entry/src/main/cpp/cellar_bridge.c",
           "-L#{sysroot}/usr/lib/aarch64-linux-ohos", "-lace_napi.z", "-Wl,-z,global",
           "-o", "entry/src/main/cpp/libs/arm64-v8a/libcellar_bridge.so"

    hap = Pathname("entry/build/default/outputs/default/entry-default-unsigned.hap").expand_path
    stage = Pathname("so-stage")
    (stage/"libs/arm64-v8a").mkpath
    cp "entry/src/main/cpp/libs/arm64-v8a/libcellar_bridge.so", stage/"libs/arm64-v8a/"
    Dir.chdir(stage) { system "zip", "-q", "-r", hap.to_s, "libs" }
    hap_entries = Utils.safe_popen_read("unzip", "-l", hap.to_s)
    odie "native bridge missing from HAP" unless hap_entries.include?("libcellar_bridge.so")

    libexec.install hap => "cellar-unsigned.hap"

    # `hap-app auto-install` requires a command named after the formula (`*-app`)
    # that accepts `install`. Forward to app-installer, swallowing the duplicate
    # `install` subcommand (app-installer's default action is install).
    installer = formula_opt_bin("app-installer")/"app-installer"
    (bin/"cellar-app").write <<~SH
      #!/bin/sh
      [ "${1:-}" = "install" ] && shift
      exec "#{installer}" \\
        --hap "#{libexec}/cellar-unsigned.hap" \\
        --bundle-id com.social4hyq.cellar \\
        --module entry --ability EntryAbility "$@"
    SH
    chmod 0755, bin/"cellar-app"

    # Assert the HAP declares the ACL permissions Cellar needs (read host brew
    # files, loopback IPC to Harbor, background if used).
    module_json = JSON.parse(Utils.safe_popen_read("unzip", "-p", libexec/"cellar-unsigned.hap", "module.json"))
    requested = module_json.fetch("module").fetch("requestPermissions").map { |p| p["name"] }
    %w[ohos.permission.INTERNET ohos.permission.CUSTOM_SANDBOX
       ohos.permission.READ_WRITE_USER_FILE].each do |perm|
      odie "missing permission in HAP: #{perm}" unless requested.include?(perm)
    end
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "cellar-app", "com.social4hyq.cellar"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    assert_path_exists bin/"cellar-app"
    assert_path_exists libexec/"cellar-unsigned.hap"
    module_json = JSON.parse(Utils.safe_popen_read("unzip", "-p", libexec/"cellar-unsigned.hap", "module.json"))
    assert_equal "com.social4hyq.cellar", module_json.dig("app", "bundleName")
  end
end
