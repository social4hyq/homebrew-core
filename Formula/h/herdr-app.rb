class HerdrApp < Formula
  desc "Herdr terminal multiplexer desktop app, unsigned OHOS HAP"
  homepage "https://herdr.dev"
  url "https://github.com/herdrdev/herdr-app/archive/refs/tags/v0.1.16.tar.gz"
  sha256 "fea3d920607f2199ed330eb3cdcb1fa3626dcea5080c92a97a296d983d6bc681"
  license "Apache-2.0"
  revision 19

  livecheck do
    url "https://github.com/herdrdev/herdr-app.git"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/herdr-app-v0.1.16-r26"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2ed8fbd271ec8ff0141fcc01f9362fcaa181a8a24789bebce1c5d7f68efadf8d"
  end

  depends_on "node" => :build
  depends_on "ohos-sdk" => :build
  depends_on "rust" => :build
  depends_on "zig@0.16" => :build
  depends_on "app-installer"
  depends_on "ohos-sdk-toolchains"
  depends_on "python@3.15"
  depends_on "social4hyq/core/herdr-core"

  patch_root = Pathname(__dir__).parent.parent

  # libghostty-vt builds from the ghostty submodule (GitHub archives omit it);
  # simdutf needs PIC for OHOS.
  resource "ghostty" do
    url "https://github.com/ghostty-org/ghostty/archive/291fd050b9e9c293c8adb6a140742649b7e42d3a.tar.gz"
    sha256 "f35b464f1aee22ffda9f6359038b9ad18a784342b4a4fa1cb97a79fb9ade79a4"

    Dir[(patch_root/"Patches/herdr-app/ghostty/*.patch").to_s].each do |path|
      patch do
        file Pathname(path).relative_path_from(patch_root).to_s
      end
    end
  end

  resource "openharmony-ability" do
    url "https://static.crates.io/crates/openharmony-ability/openharmony-ability-1.0.0-beta.5.crate"
    sha256 "c3d65db22273d3afdef8fd8eb9411546243aae365236829e67a8deca79eed5f1"

    Dir[(patch_root/"Patches/herdr-app/openharmony-ability/*.patch").to_s].each do |path|
      patch do
        file Pathname(path).relative_path_from(patch_root).to_s
      end
    end
  end

  resource "gpui-ohos" do
    url "https://static.crates.io/crates/gpui-ohos/gpui-ohos-0.0.1-beta.0.crate"
    sha256 "77231f68750da0ae969c9b6d8054a82376ebcc522d0baff57a4a2bd434f331ce"

    Dir[(patch_root/"Patches/herdr-app/gpui-ohos/*.patch").to_s].each do |path|
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

  Dir[(patch_root/"Patches/herdr-app/ohos/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/herdr-app/hap/AppScope/app.json5
    Resources/herdr-app/hap/AppScope/resources/base/element/string.json
    Resources/herdr-app/hap/AppScope/resources/base/media/example_icon.png
    Resources/herdr-app/hap/build-profile.json5
    Resources/herdr-app/hap/entry/build-profile.json5
    Resources/herdr-app/hap/entry/hvigorfile.ts
    Resources/herdr-app/hap/entry/oh-package-lock.json5
    Resources/herdr-app/hap/entry/oh-package.json5
    Resources/herdr-app/hap/entry/src/main/ets/entryability/EntryAbility.ets
    Resources/herdr-app/hap/entry/src/main/ets/pages/Index.ets
    Resources/herdr-app/hap/entry/src/main/ets/types/herdr_app/Index.d.ts
    Resources/herdr-app/hap/entry/src/main/ets/types/herdr_app/oh-package.json5
    Resources/herdr-app/hap/entry/src/main/module.json5
    Resources/herdr-app/hap/entry/src/main/resources/base/element/color.json
    Resources/herdr-app/hap/entry/src/main/resources/base/element/string.json
    Resources/herdr-app/hap/entry/src/main/resources/base/media/example_icon.png
    Resources/herdr-app/hap/entry/src/main/resources/base/profile/main_pages.json
    Resources/herdr-app/hap/hvigor/hvigor-config.json5
    Resources/herdr-app/hap/hvigorfile.ts
    Resources/herdr-app/hap/oh-package-lock.json5
    Resources/herdr-app/hap/oh-package.json5
    Resources/herdr-app/scripts/herdr-app.sh
    Resources/herdr-app/scripts/herdr-bridge.py
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
    res = tap_root/"Resources/herdr-app"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    # HAP packaging uses the private electron-ohos-ci image
    # (OHOS_CI_IMAGE_OVERRIDES) with the proprietary CLT at
    # /opt/electron-ohos-clt.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "herdr-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['herdr-app']"
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
                    "herdr-app-unsigned.hap"

    cp res/"scripts/herdr-app.sh", libexec/"herdr-app.sh"
    cp res/"scripts/herdr-bridge.py", libexec/"herdr-bridge.py"
    chmod 0755, [libexec/"herdr-app.sh", libexec/"herdr-bridge.py"]
    (bin/"herdr-app").write_env_script libexec/"herdr-app.sh",
      HERDR_APP_HAP:         libexec/"herdr-app-unsigned.hap",
      HERDR_APP_HDC_DEFAULT: formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      HERDR_APP_BRIDGE:      libexec/"herdr-bridge.py",
      HERDR_APP_HC:          formula_opt_bin("herdr-core")/"hc",
      HERDR_APP_PYTHON:      formula_opt_bin("python@3.15")/"python3"
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "herdr-app", "com.social4hyq.herdrapp"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    hap = libexec/"herdr-app-unsigned.hap"
    manifest = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "entry", manifest.dig("module", "name")
    permissions = manifest.dig("module", "requestPermissions").map { |permission| permission["name"] }
    assert_includes permissions, "ohos.permission.INTERNET"
    assert_includes permissions, "ohos.permission.READ_PASTEBOARD"
    assert_equal "com.social4hyq.herdrapp", manifest.dig("app", "bundleName")
    # The Rust side bridges permission requests through PermissionPlugin; without
    # registering it, READ_PASTEBOARD is declared but never prompts for access.
    ability_source = (Pathname(__FILE__).expand_path.dirname.parent.parent/
                      "Resources/herdr-app/hap/entry/src/main/ets/entryability/EntryAbility.ets").read
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

    assert_match "Usage: herdr-app", shell_output("#{bin}/herdr-app --help")

    # Run the bridge and install flow with stand-ins for hc and app-installer:
    # the token ends up in the HAP and the bridge answers only it.
    port = free_port
    (testpath/"tmp").mkpath
    (testpath/"bin").mkpath
    (testpath/"hc").write "#!/bin/sh\nexec cat\n"
    (testpath/"bin/app-installer").write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{testpath}/installer-args
      while [ "$#" -gt 0 ]; do
        [ "$1" = "--hap" ] && cp "$2" "#{testpath}/injected.hap"
        shift
      done
    SH
    chmod 0755, [testpath/"hc", testpath/"bin/app-installer"]
    python = formula_opt_bin("python@3.15")/"python3"
    env = {
      "HERDR_APP_STATE"  => (testpath/"state").to_s,
      "HERDR_APP_PORT"   => port.to_s,
      "HERDR_APP_HC"     => (testpath/"hc").to_s,
      "HERDR_APP_BRIDGE" => (libexec/"herdr-bridge.py").to_s,
      "HERDR_APP_PYTHON" => python.to_s,
      "HERDR_APP_HAP"    => hap.to_s,
      "APP_INSTALLER"    => (testpath/"bin/app-installer").to_s,
      "TMPDIR"           => (testpath/"tmp").to_s,
      "XDG_CACHE_HOME"   => (testpath/"cache").to_s,
      "PATH"             => "#{testpath}/bin:#{ENV["PATH"]}",
    }
    script = libexec/"herdr-app.sh"
    begin
      with_env(env) do
        system script, "install"
        assert_match "token:          accepted", shell_output("#{script} bridge status")
      end
      conf = (testpath/"state/bridge.conf").read
      token = conf[/^token=(\h{64})$/, 1]
      refute_nil token
      assert_match "addr=127.0.0.1:#{port}", conf
      assert_equal conf, shell_output("unzip -p #{testpath}/injected.hap resources/rawfile/bridge.conf")
      assert_empty Dir[testpath/"tmp/*"], "the staged HAP that holds the token was not removed"
      assert_equal (testpath/"tmp").to_s, (testpath/"state/bridge.tmpdir").read.strip

      # A TMPDIR that cannot hold a directory must not fail the install: the
      # stage falls back to the app's cache (hmdfs inherits the parent owner).
      (testpath/"bad-tmp").write "not a directory"
      with_env(env.merge("TMPDIR" => (testpath/"bad-tmp").to_s)) do
        system script, "install"
      end
      assert_equal conf, shell_output("unzip -p #{testpath}/injected.hap resources/rawfile/bridge.conf")
      assert_empty Dir[testpath/"cache/herdr-app-inject.*"], "the fallback stage was not removed"
      assert_equal (testpath/"cache").to_s, (testpath/"state/bridge.tmpdir").read.strip

      check = <<~'PY'
        import socket, sys
        port, token = int(sys.argv[1]), sys.argv[2].encode()
        def first_reply(line):
            with socket.create_connection(("127.0.0.1", port), timeout=5) as conn:
                conn.sendall(line)
                return conn.makefile("rb").readline()
        assert first_reply(b"HERDR-AUTH " + token + b"\n") == b"OK\n"
        assert first_reply(b"HERDR-AUTH " + b"0" * 64 + b"\n") == b"DENIED\n"
        assert first_reply(b'{"jsonrpc":"2.0","id":0,"method":"hello"}\n') == b"DENIED\n"
      PY
      system python, "-c", check, port.to_s, token
    ensure
      with_env(env) { quiet_system script, "bridge", "stop" }
    end

    # The state follows the real home and not XDG_CONFIG_HOME (brew's post_install run gets a
    # throw-away one), and a bridge.conf that earlier versions kept there is adopted once.
    (testpath/"xdg/herdr-app").mkpath
    legacy_conf = "addr=127.0.0.1:#{port}\ntoken=#{"a" * 64}\n"
    (testpath/"xdg/herdr-app/bridge.conf").write legacy_conf
    home_env = env.except("HERDR_APP_STATE")
    home_env["HOME"] = (testpath/"home").to_s
    home_env["XDG_CONFIG_HOME"] = (testpath/"xdg").to_s
    status = with_env(home_env) { shell_output("#{script} bridge status 2>&1", 1) }
    assert_match "config:         #{testpath}/home/.config/herdr-app/bridge.conf", status
    assert_equal legacy_conf, (testpath/"home/.config/herdr-app/bridge.conf").read

    # Top-level stop/status manage the bridge; uninstall goes through
    # app-installer and keeps the app's data unless --purge is given.
    with_env(env) do
      shell_output("#{script} stop 2>&1")
      assert_match "bridge is not running", shell_output("#{script} stop 2>&1")
      assert_match "not running", shell_output("#{script} status 2>&1", 1)
      shell_output("#{script} uninstall --purge --device tablet-1")
      assert_equal %w[uninstall --bundle-id com.social4hyq.herdrapp --device tablet-1 --purge],
                   (testpath/"installer-args").read.lines(chomp: true)
      shell_output("#{script} uninstall")
      assert_equal %w[uninstall --bundle-id com.social4hyq.herdrapp],
                   (testpath/"installer-args").read.lines(chomp: true)
    end
    with_env({ "HDC_TARGET" => "env-device" }.merge(env)) do
      shell_output("#{script} uninstall")
    end
    assert_equal %w[uninstall --bundle-id com.social4hyq.herdrapp --device env-device],
                 (testpath/"installer-args").read.lines(chomp: true)
    assert_match "uninstall", shell_output("#{bin}/herdr-app --help")
  end
end
