class HarborDesktop < Formula
  desc "Systemd-like service manager for HarmonyOS PC, as a tiny pure-ArkTS HAP"
  homepage "https://github.com/social4hyq/harbor-app"
  url "https://github.com/social4hyq/harbor-app/archive/refs/tags/v0.4.1.tar.gz"
  sha256 "74b6d19cc0af97b1b88972248eb67d6a0cbed8b989ff82bf1d15170761b2b7ee"
  license "MIT"
  revision 3

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/harbor-desktop-v0.4.1-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "91e0071e4c21b7108a19c1fad12650da9502a9474dbcb38688056de8f38998de"
  end

  depends_on "node" => :build
  depends_on "ohos-hap-clt" => :build
  depends_on "ohos-sdk" => :build
  depends_on "zip" => :build
  depends_on "python@3.15"

  # Publicly mirrored official CLT replaces the private electron-ohos-ci image.
  resource "command-line-tools" do
    url "https://s3.oheco.org/command-line-tools/26.0.0.201/commandline-tools-harmonyos-26.0.0.201.tar.gz"
    sha256 "60929c00ae486cc038ea48145497ad34dbd4ac6a25c3f2fa895ce74afb4607f5"
  end

  def install
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

    system "node", clt/"ohpm/bin/pm-cli.js", "install"
    system hap_clt.to_s, "hvigor", clt.to_s, "assembleHap",
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

    libexec.install hap => "harbor-desktop-unsigned.hap"
    bin.install "harbor"

    (pkgshare/"apps.json.default").write <<~JSON
      {
        "autoHideOnLaunch": true,
        "apps": []
      }
    JSON

    # Assert the HAP declares the ACL permissions Harbor needs.
    module_json = JSON.parse(
      Utils.safe_popen_read("unzip", "-p", libexec/"harbor-desktop-unsigned.hap", "module.json"),
    )
    requested = module_json.fetch("module").fetch("requestPermissions").map { |p| p["name"] }
    %w[ohos.permission.INTERNET ohos.permission.CUSTOM_SANDBOX
       ohos.permission.READ_WRITE_USER_FILE ohos.permission.KEEP_BACKGROUND_RUNNING].each do |perm|
      odie "missing permission in HAP: #{perm}" unless requested.include?(perm)
    end

    # The HAP is delivered through app.json; deployment is an explicit
    # `ohos-app install harbor-desktop`. The upstream CLI stays independent.
    # Descriptor is written at build time with the real HAP digest and version.
    (pkgshare/"ohos").mkpath
    hap = libexec/"harbor-desktop-unsigned.hap"
    hap_sha = Digest::SHA256.file(hap).hexdigest
    descriptor = {
      "schema_version" => 1,
      "id"             => "social4hyq/core/harbor-desktop",
      "artifact"       => {
        "format"       => "hap",
        "path"         => "../../../libexec/harbor-desktop-unsigned.hap",
        "sha256"       => hap_sha,
        "api"          => 12,
        "abis"         => ["arm64-v8a"],
        "bundle_id"    => "com.social4hyq.harbor",
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
    # The upstream CLI is delivered independently of HAP deployment.
    help = shell_output("#{bin}/harbor --help")
    assert_match "brew services", help
    assert_match "discover", help
    refute_path_exists bin/"harbor-app"
    assert_path_exists libexec/"harbor-desktop-unsigned.hap"
    assert_path_exists pkgshare/"apps.json.default"

    # Descriptor schema, id, digest and variants must match the HAP.
    descriptor = JSON.parse((pkgshare/"ohos/app.json").read)
    assert_equal 1, descriptor["schema_version"]
    assert_equal "social4hyq/core/harbor-desktop", descriptor["id"]
    hap = libexec/"harbor-desktop-unsigned.hap"
    assert_equal Digest::SHA256.file(hap).hexdigest, descriptor.dig("artifact", "sha256")
    assert_equal "com.social4hyq.harbor", descriptor.dig("artifact", "bundle_id")
    assert_equal "basic", descriptor.dig("variants", "default")

    module_json = JSON.parse(Utils.safe_popen_read("unzip", "-p", hap, "module.json"))
    assert_equal "com.social4hyq.harbor", module_json.dig("app", "bundleName")
  end
end
