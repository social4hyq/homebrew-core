class HerdrApp < Formula
  desc "Herdr terminal multiplexer desktop app, unsigned OHOS HAP"
  homepage "https://herdr.dev"
  url "https://github.com/herdrdev/herdr-app/archive/refs/tags/v0.1.16.tar.gz"
  sha256 "fea3d920607f2199ed330eb3cdcb1fa3626dcea5080c92a97a296d983d6bc681"
  license "Apache-2.0"
  revision 1

  livecheck do
    url "https://github.com/herdrdev/herdr-app.git"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    strategy :git
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/herdr-app-v0.1.16-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "60c50dd2cbfb477916776d9c891588aa55f3cefbaeac955b5e2b081de94928c1"
  end

  depends_on "node" => :build
  depends_on "ohos-sdk" => :build
  depends_on "rust" => :build
  depends_on "zig@0.16" => :build
  depends_on "app-installer"
  depends_on "ohos-sdk-toolchains"
  depends_on "python@3.15"
  depends_on "social4hyq/core/herdr-core"

  # The terminal engine builds libghostty-vt from the ghostty submodule, which
  # GitHub archives leave out. Its simdutf package only requests PIC for
  # musl/android/freebsd, so the OHOS ABI fails to link with R_AARCH64_ABS64
  # relocation errors.
  resource "ghostty" do
    url "https://github.com/ghostty-org/ghostty/archive/291fd050b9e9c293c8adb6a140742649b7e42d3a.tar.gz"
    sha256 "f35b464f1aee22ffda9f6359038b9ad18a784342b4a4fa1cb97a79fb9ade79a4"

    patch do
      file "Patches/herdr-app/ghostty/0001-simdutf-pic-ohos.patch"
    end
  end

  # The JS runtime's sys crate picks its pre-generated bindings by target
  # triple and ships none for OHOS, so Cargo.toml points the quickjs-jit crates
  # at this checkout (the revision Cargo.lock pins) and install adds the file.
  resource "quickjs-jit" do
    url "https://github.com/longbridge/quickjs-jit/archive/96593cd7a54440ac060a391b8baea7e9a3cf1393.tar.gz"
    sha256 "6c11680bff4b74ca55288a34ca00b6a55bcb68a6b63688c84211aaa7aefc94ec"
  end

  # The quickjs-jit-sys build compiles QuickJS from the sys/quickjs submodule,
  # which GitHub archives leave out as well.
  resource "quickjs-ng" do
    url "https://github.com/quickjs-ng/quickjs/archive/fd0a0210b7be00957751871e7e01b8291268fc29.tar.gz"
    sha256 "39d931489e99f80b496f900f88d67d7aad6b5f25ce83810a408eb42f6af6839e"
  end

  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/herdr-app/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end

  # The cargo build runs `zig build`, which fetches its packages, and ohpm
  # fetches the ArkTS packages. Both servers now and then answer 5xx or a
  # broken response, which is not worth a 30 minute build: retry the step.
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
    # HAP packaging. CI runs in the private electron-ohos-ci image (selected
    # via the OHOS_CI_IMAGE_OVERRIDES repo variable), which bakes the
    # HarmonyOS command-line toolchain at /opt/electron-ohos-clt, repacked
    # from a licensed system CLT install and not publicly redistributable.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "herdr-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['herdr-app']"
    end

    resource("ghostty").stage(buildpath/"vendor/ghostty")
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

    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    payload = tap_root/"Patches/herdr-app"
    hap = buildpath/"hap"
    cp_r payload/"hap", hap
    libs = hap/"entry/libs/arm64-v8a"
    libs.mkpath
    cp "target/aarch64-unknown-linux-ohos/release/libherdr_app.so", libs/"libopenharmony_ability.so"
    system ndk/"llvm/bin/llvm-strip", "--strip-unneeded", libs/"libopenharmony_ability.so"
    cp ndk/"llvm/lib/aarch64-linux-ohos/libc++_shared.so", libs

    # brew's sanitized build env drops the container's LD_LIBRARY_PATH, but
    # ohos_packing_tool needs the SDK clang runtimes and the libhilog
    # stderr adapter baked into the image.
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    # A container inheriting RLIMIT_NOFILE near 1e9 drives the musl FD-table
    # sizing into a refused mapping; cap it for the hvigor process tree
    # (only ever lowering, never raising an environment's existing limit).
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd hap do
      retrying { system "node", clt/"ohpm/bin/pm-cli.js", "install" }
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    libexec.install hap/"entry/build/default/outputs/default/entry-default-unsigned.hap" =>
                    "herdr-app-unsigned.hap"

    cp payload/"scripts/herdr-app.sh", libexec/"herdr-app.sh"
    cp payload/"scripts/herdr-bridge.py", libexec/"herdr-bridge.py"
    chmod 0755, [libexec/"herdr-app.sh", libexec/"herdr-bridge.py"]
    (bin/"herdr-app").write_env_script libexec/"herdr-app.sh",
      HERDR_APP_HAP:         libexec/"herdr-app-unsigned.hap",
      HERDR_APP_HDC_DEFAULT: formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      HERDR_APP_BRIDGE:      libexec/"herdr-bridge.py",
      HERDR_APP_HC:          formula_opt_bin("herdr-core")/"hc",
      HERDR_APP_PYTHON:      formula_opt_bin("python@3.15")/"python3"
  end

  def caveats
    <<~EOS
      The HAP is unsigned in the bottle. Connect and unlock the device, then run
      `herdr-app install`. app-installer handles Huawei Developer login, local
      debug profile generation, signing, installation, and launch. Later, open
      the app with `herdr-app start`.

      The app cannot start the host's `hc`, so it reaches herdr-core through a
      bridge that `herdr-app install` and `herdr-app start` run for you
      (`herdr-app bridge status|stop|restart`). The bridge listens on 127.0.0.1
      only and answers only a connection that starts with a token. The token is
      made at install time, kept in $XDG_CONFIG_HOME/herdr-app/bridge.conf (mode
      600) and baked into the installed app. `herdr-app install --new-token`
      replaces it.
    EOS
  end

  test do
    hap = libexec/"herdr-app-unsigned.hap"
    assert_match "libs/arm64-v8a/libopenharmony_ability.so", shell_output("unzip -l #{hap}")

    manifest = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal "entry", manifest.dig("module", "name")
    permissions = manifest.dig("module", "requestPermissions").map { |permission| permission["name"] }
    assert_includes permissions, "ohos.permission.INTERNET"
    assert_equal "com.social4hyq.herdrapp", manifest.dig("app", "bundleName")

    assert_match "Usage: herdr-app", shell_output("#{bin}/herdr-app --help")
    wrapper = (bin/"herdr-app").read
    assert_match "HERDR_APP_BRIDGE=\"#{libexec}/herdr-bridge.py\"", wrapper
    assert_match "HERDR_APP_PYTHON=", wrapper
    assert_match "HERDR_APP_HC=", wrapper

    # The bridge and the install flow, run from the script itself (the wrapper above exports its own hc and
    # python) with a stand-in for hc and for app-installer: the token ends up in the HAP that would be signed,
    # the bridge answers it and nothing else.
    port = free_port
    (testpath/"tmp").mkpath
    (testpath/"bin").mkpath
    (testpath/"hc").write "#!/bin/sh\nexec cat\n"
    (testpath/"bin/app-installer").write <<~SH
      #!/bin/sh
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
      "TMPDIR"           => (testpath/"tmp").to_s,
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
  end
end
