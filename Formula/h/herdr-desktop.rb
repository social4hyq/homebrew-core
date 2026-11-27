class HerdrDesktop < Formula
  desc "Herdr terminal multiplexer desktop app, unsigned OHOS HAP"
  homepage "https://herdr.dev"
  url "https://github.com/herdrdev/herdr-app/archive/refs/tags/v0.1.18.tar.gz"
  sha256 "0c442fd54231dee2aca661661b50f4177ca04b55966c572f26cf06c629e9e59d"
  license "Apache-2.0"
  revision 6

  livecheck do
    url "https://github.com/herdrdev/herdr-app.git"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/herdr-desktop-v0.1.18-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "60d96920a6b2263aeea04355ec489685fe46b8fa01b85b0d7323fa9dcfe9ffd2"
  end

  depends_on "node" => :build
  depends_on "ohos-sdk" => :build
  depends_on "rust" => :build
  depends_on "zig@0.16" => :build
  depends_on "ohos-sdk-toolchains"
  depends_on "python@3.15"
  depends_on "social4hyq/core/herdr-core"

  patch_root = Pathname(__dir__).parent.parent

  # libghostty-vt builds from the ghostty submodule (GitHub archives omit it);
  # simdutf needs PIC for OHOS.
  resource "ghostty" do
    url "https://github.com/ghostty-org/ghostty/archive/291fd050b9e9c293c8adb6a140742649b7e42d3a.tar.gz"
    sha256 "f35b464f1aee22ffda9f6359038b9ad18a784342b4a4fa1cb97a79fb9ade79a4"

    Dir[(patch_root/"Patches/herdr-desktop/ghostty/*.patch").to_s].each do |path|
      patch do
        file Pathname(path).relative_path_from(patch_root).to_s
      end
    end
  end

  resource "openharmony-ability" do
    url "https://static.crates.io/crates/openharmony-ability/openharmony-ability-1.0.0-beta.5.crate"
    sha256 "c3d65db22273d3afdef8fd8eb9411546243aae365236829e67a8deca79eed5f1"

    Dir[(patch_root/"Patches/herdr-desktop/openharmony-ability/*.patch").to_s].each do |path|
      patch do
        file Pathname(path).relative_path_from(patch_root).to_s
      end
    end
  end

  resource "gpui-ohos" do
    url "https://static.crates.io/crates/gpui-ohos/gpui-ohos-0.0.1-beta.0.crate"
    sha256 "77231f68750da0ae969c9b6d8054a82376ebcc522d0baff57a4a2bd434f331ce"

    Dir[(patch_root/"Patches/herdr-desktop/gpui-ohos/*.patch").to_s].each do |path|
      patch do
        file Pathname(path).relative_path_from(patch_root).to_s
      end
    end
  end

  # The JS runtime's sys crate has no OHOS bindings; Cargo.toml points the
  # quickjs-jit crates at this checkout and install adds the file.
  resource "quickjs-jit" do
    url "https://github.com/longbridge/quickjs-jit/archive/96593cd7a54440ac060a391b8baea7e9a3cf1393.tar.gz"
    sha256 "6c11680bff4b74ca55288a34ca00b6a55bcb68a6b63688c84211aaa7aefc94ec"
  end

  # quickjs-jit-sys builds QuickJS from the sys/quickjs submodule (also omitted
  # from GitHub archives).
  resource "quickjs-ng" do
    url "https://github.com/quickjs-ng/quickjs/archive/fd0a0210b7be00957751871e7e01b8291268fc29.tar.gz"
    sha256 "39d931489e99f80b496f900f88d67d7aad6b5f25ce83810a408eb42f6af6839e"
  end

  Dir[(patch_root/"Patches/herdr-desktop/ohos/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/herdr-desktop/hap/AppScope/app.json5
    Resources/herdr-desktop/hap/AppScope/resources/base/element/string.json
    Resources/herdr-desktop/hap/AppScope/resources/base/media/example_icon.png
    Resources/herdr-desktop/hap/build-profile.json5
    Resources/herdr-desktop/hap/entry/build-profile.json5
    Resources/herdr-desktop/hap/entry/hvigorfile.ts
    Resources/herdr-desktop/hap/entry/oh-package-lock.json5
    Resources/herdr-desktop/hap/entry/oh-package.json5
    Resources/herdr-desktop/hap/entry/src/main/ets/entryability/EntryAbility.ets
    Resources/herdr-desktop/hap/entry/src/main/ets/pages/Index.ets
    Resources/herdr-desktop/hap/entry/src/main/ets/types/herdr_app/Index.d.ts
    Resources/herdr-desktop/hap/entry/src/main/ets/types/herdr_app/oh-package.json5
    Resources/herdr-desktop/hap/entry/src/main/module.json5
    Resources/herdr-desktop/hap/entry/src/main/resources/base/element/color.json
    Resources/herdr-desktop/hap/entry/src/main/resources/base/element/string.json
    Resources/herdr-desktop/hap/entry/src/main/resources/base/media/example_icon.png
    Resources/herdr-desktop/hap/entry/src/main/resources/base/profile/main_pages.json
    Resources/herdr-desktop/hap/hvigor/hvigor-config.json5
    Resources/herdr-desktop/hap/hvigorfile.ts
    Resources/herdr-desktop/hap/oh-package-lock.json5
    Resources/herdr-desktop/hap/oh-package.json5
  ].freeze

  # zig and ohpm fetch packages over the network; retry on transient 5xx.
  def retrying(attempts = 3)
    tries = 0
    begin
      yield
    rescue BuildError
      tries += 1
      raise if tries >= attempts

      sleep 30
      retry
    end
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/herdr-desktop"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    # HAP packaging uses the private electron-ohos-ci image
    # (OHOS_CI_IMAGE_OVERRIDES) with the proprietary CLT at
    # /opt/electron-ohos-clt.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "#{name} builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['#{name}']"
    end

    resource("ghostty").stage(buildpath/"vendor/ghostty")
    resource("openharmony-ability").stage(buildpath/"vendor/openharmony-ability")
    resource("gpui-ohos").stage(buildpath/"vendor/gpui-ohos")
    quickjs = buildpath/"vendor/quickjs-jit-src/96593cd"
    resource("quickjs-jit").stage(quickjs)
    resource("quickjs-ng").stage(quickjs/"sys/quickjs")
    # Same ABI as the aarch64 Linux bindings, byte for byte.
    cp quickjs/"sys/src/bindings/aarch64-unknown-linux-gnu.rs",
       quickjs/"sys/src/bindings/aarch64-unknown-linux-ohos.rs"

    ndk = formula_opt_prefix("ohos-sdk")/"native"
    ENV["OHOS_NDK_HOME"] = ndk.to_s
    # rustc asks the linker for libgcc_s, which the NDK does not have: give it an empty one.
    stubs = buildpath/"target/ohos-stubs"
    stubs.mkpath
    (stubs/"empty.c").write "/* stub */\n"
    system ndk/"llvm/bin/clang", "--target=aarch64-linux-ohos", "--sysroot=#{ndk}/sysroot",
           "-shared", "-fPIC", "-o", stubs/"libgcc_s.so", stubs/"empty.c"
    ENV.append "RUSTFLAGS", "-L native=#{stubs}", " "

    retrying do
      system "cargo", "build", "--lib", "--release", "--locked", "--target", "aarch64-unknown-linux-ohos"
    end

    hap = buildpath/"hap"
    cp_r res/"hap", hap
    libs = hap/"entry/libs/arm64-v8a"
    libs.mkpath
    cp "target/aarch64-unknown-linux-ohos/release/libherdr_app.so", libs/"libopenharmony_ability.so"
    system ndk/"llvm/bin/llvm-strip", "--strip-unneeded", libs/"libopenharmony_ability.so"
    cp ndk/"llvm/lib/aarch64-linux-ohos/libc++_shared.so", libs

    # ohos_packing_tool needs SDK libraries outside brew's sanitized search path.
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    # An oversized RLIMIT_NOFILE breaks the musl FD table in hvigor.
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd hap do
      retrying { system "node", clt/"ohpm/bin/pm-cli.js", "install" }
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    libexec.install hap/"entry/build/default/outputs/default/entry-default-unsigned.hap" =>
                    "herdr-desktop-unsigned.hap"

    # The HAP is delivered through app.json; deployment is an explicit
    # `ohos-app install herdr-desktop`. The upstream CLI stays independent.
    # Descriptor is written at build time with the real HAP digest and version.
    (pkgshare/"ohos").mkpath
    hap = libexec/"herdr-desktop-unsigned.hap"
    hap_sha = Digest::SHA256.file(hap).hexdigest
    descriptor = {
      "schema_version" => 1,
      "id"             => "social4hyq/core/herdr-desktop",
      "artifact"       => {
        "format"       => "hap",
        "path"         => "../../libexec/herdr-desktop-unsigned.hap",
        "sha256"       => hap_sha,
        "api"          => 12,
        "abis"         => ["arm64-v8a"],
        "bundle_id"    => "com.social4hyq.herdrapp",
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
    refute_path_exists bin/"herdr-app"

    descriptor = JSON.parse((pkgshare/"ohos/app.json").read)
    assert_equal 1, descriptor["schema_version"]
    assert_equal "social4hyq/core/herdr-desktop", descriptor["id"]
    hap = libexec/"herdr-desktop-unsigned.hap"
    assert_equal Digest::SHA256.file(hap).hexdigest, descriptor.dig("artifact", "sha256")
    assert_equal "com.social4hyq.herdrapp", descriptor.dig("artifact", "bundle_id")
    assert_equal "entry", descriptor.dig("launch", "module")
    assert_equal "EntryAbility", descriptor.dig("launch", "ability")
    assert_equal "basic", descriptor.dig("variants", "default")
    assert_equal({}, descriptor.dig("variants", "definitions", "basic"))

    manifest = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "entry", manifest.dig("module", "name")
    permissions = manifest.dig("module", "requestPermissions").map { |permission| permission["name"] }
    assert_includes permissions, "ohos.permission.INTERNET"
    assert_includes permissions, "ohos.permission.READ_PASTEBOARD"
    assert_equal "com.social4hyq.herdrapp", manifest.dig("app", "bundleName")
    # The Rust side bridges permission requests through PermissionPlugin; without
    # registering it, READ_PASTEBOARD is declared but never prompts for access.
    ability_source = (Pathname(__FILE__).expand_path.dirname.parent.parent/
                      "Resources/herdr-desktop/hap/entry/src/main/ets/entryability/EntryAbility.ets").read
    assert_match "new PermissionPlugin()", ability_source

    system "unzip", "-o", hap, "resources/base/media/example_icon.png", "-d", testpath/"icon"
    assert_equal "66be46ebed8e540bb023dbf71db04c758b2de14b64b643d7cafbcc31268fbd4c",
                 (testpath/"icon/resources/base/media/example_icon.png").sha256

    index = shell_output("unzip -p #{hap} resources.index").b
    refute_includes index, "GPUI OHOS Example".b
    assert_includes index, "Herdr".b

    # A link clicked in the terminal opens the system browser through the host's aa, so the library names it.
    library = shell_output("unzip -p #{hap} libs/arm64-v8a/libopenharmony_ability.so").b
    assert_includes library, "com.huawei.hmos.browser".b
    assert_includes library, "herdr-core keeps them running".b
  end
end
