class OrcaApp < Formula
  desc "Desktop shell for the Orca agent runtime (Electron window on its web client)"
  homepage "https://github.com/stablyai/orca"
  # Version follows the Orca release; shell sources live in Resources/orca-app
  # and the host runtime comes from the `orca` formula (same upstream tag).
  url "https://github.com/stablyai/orca/archive/refs/tags/v1.4.272.tar.gz"
  sha256 "f7eae968825acde3deced239d07f828a04e54e0962a6e4d1d7c8b12129e8221d"
  # Tap-authored shell scripts (MIT) on the CPF-Electron runtime (mixed
  # MIT/BSD/LGPL).
  license :cannot_represent

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/orca-app-v1.4.272-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "08dec990f084c96497e245100f0344cbbbdf797ff300e7a828bef06b6595a774"
  end

  depends_on "openjdk" => :build
  depends_on "app-installer"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "orca"
  depends_on "unzip"
  depends_on "zip"

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/install-lib.sh
    Resources/orca-app/app/attach.cjs
    Resources/orca-app/app/config.json
    Resources/orca-app/app/main.cjs
    Resources/orca-app/app/package.json
    Resources/orca-app/app/relay.cjs
    Resources/orca-app/app/tray.cjs
    Resources/orca-app/app/waiting.html
    Resources/orca-app/assets/icon.png
    Resources/orca-app/assets/tray-icon.png
    Resources/orca-app/scripts/install-desktop.sh
    Resources/orca-app/scripts/orca-desktop.sh
    Resources/orca-app/tests/attach.test.cjs
    Resources/orca-app/tests/cli-env.test.cjs
    Resources/orca-app/tests/close-handler.test.cjs
    Resources/orca-app/tests/fake-orca.cjs
    Resources/orca-app/tests/relay.test.cjs
    Resources/orca-app/tests/shell-flow.test.cjs
    Resources/orca-app/tests/shell-harness.cjs
  ].freeze

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/orca-app"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    %w[main.cjs attach.cjs relay.cjs tray.cjs package.json config.json waiting.html].each do |name|
      cp res/"app"/name, app/name
    end

    cp res/"assets/icon.png", app/"app-icon.png"
    cp res/"assets/tray-icon.png", app/"tray-icon.png"

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.orca"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp res/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    # Locale overrides would otherwise keep the Electron launcher label.
    (shell.glob("AppScope/resources/*/element/string.json") +
     shell.glob("electron/src/main/resources/*/element/string.json")).each do |file|
      strings = JSON.parse(file.read)
      strings.fetch("string").each do |entry|
        case entry["name"]
        when "app_name", "EntryAbility_label" then entry["value"] = "Orca"
        end
      end
      rm file
      file.write JSON.pretty_generate(strings) + "\n"
    end

    # Remove template signing settings and select the shared toolchain's SDK;
    # this profile is strict JSON.
    profile = JSON.parse((shell/"build-profile.json5").read)
    profile.fetch("app").fetch("products").each do |product|
      product.delete("signingConfig")
      product["compatibleSdkVersion"] = "6.0.0(20)"
    end
    profile.fetch("app").delete("signingConfigs")
    profile_file = shell/"build-profile.json5"
    rm profile_file
    profile_file.write JSON.pretty_generate(profile) + "\n"
    inreplace shell/"electron/src/main/module.json5", '"mainElement": "EntryAbility",',
              '"mainElement": "EntryAbility", "extractNativeLibs": true,'

    # The shell only talks to the runtime over loopback; restricted
    # permissions go into the ACL variant (module-acl.json).
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\r?\n    \],/m,
              <<~JSON5.chomp
                "requestPermissions": [
                      { "name": "ohos.permission.INTERNET" },
                      { "name": "ohos.permission.GET_NETWORK_INFO" },
                      { "name": "ohos.permission.MICROPHONE", "reason": "$string:microphone", "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" } }
                    ],
              JSON5

    # windowStageClose hides the ability and returns true, which tells the
    # system not to close the window, so the window goes to the tray. Returning
    # false let the system close it right after the hide: the ability's session
    # was destroyed and the whole app was killed and relaunched. The tray quit
    # calls app.exit() to bypass that handler.
    close_handler = [
      "    super.onWindowStageCreate(windowStage);",
      "    try {",
      "      windowStage.on('windowStageClose', () => {",
      "        if (CheckEmptyUtils.isEmpty(this.xcomponentId)) {",
      "          return false;",
      "        }",
      "        const widgetId = Number(this.xcomponentId.substring(ConfigData.WINDOW_PREFIX.length));",
      "        Inject.getOrCreate(AppWindowAdapter).hideWindow(widgetId);",
      "        return true;",
      "      });",
      "    } catch (exception) {",
      "      LogUtil.error(TAG, 'Failed to register window close handler: ' + JSON.stringify(exception));",
      "    }",
      "",
    ].join("\n")
    inreplace shell/"web_engine/src/main/ets/ability/WebAbility.ets",
              "    super.onWindowStageCreate(windowStage);\n", close_handler

    # The proprietary CLT is supplied by the CI image, not distributed by the tap.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "orca-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['orca-app']"
    end

    # ohos_packing_tool needs SDK libraries outside brew's sanitized search path.
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    # hvigor's PackageHap runs the SDK's hap-sign-tool through `java`.
    ENV["JAVA_HOME"] = formula_opt_prefix("openjdk").to_s
    ENV.prepend_path "PATH", formula_opt_bin("openjdk")
    ENV["LD_LIBRARY_PATH"] = [
      "#{clt}/lib",
      "#{clt}/sdk/default/hms/toolchains/lib",
      "#{clt}/sdk/default/openharmony/toolchains/lib",
      "#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos",
    ].join(":")
    ENV.delete("NODE_OPTIONS")
    # An oversized RLIMIT_NOFILE breaks the musl FD table in hvigor.
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd shell do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    libexec.install shell/"electron/build/default/outputs/default/electron-default-unsigned.hap" =>
                    "orca-app-unsigned.hap"

    # ACL variant: CUSTOM_SANDBOX and READ_WRITE_USER_FILE let the shell spawn
    # `orca` and read the host profile; the kernel ACLs keep WebAssembly and
    # READ_PASTEBOARD makes paste work.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"orca-app-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX
       ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION
       ohos.permission.READ_PASTEBOARD].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    pkgshare.mkpath
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # Pathname#install would move files out of the read-only CI tap.
    cp res/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    chmod 0755, pkgshare/"hap-app-install-lib.sh"
    cp res/"scripts/orca-desktop.sh", libexec/"orca-desktop.sh"
    chmod 0755, libexec/"orca-desktop.sh"
    tool_path = [formula_opt_bin("node"), formula_opt_bin("zip"), formula_opt_bin("unzip"), "$PATH"].join(":")
    (bin/"orca-app").write_env_script libexec/"orca-desktop.sh",
      ORCA_DESKTOP_ROOT:           formula_opt_prefix("orca")/"libexec",
      ORCA_DESKTOP_ORCA_BIN:       formula_opt_bin("orca")/"orca",
      ORCA_DESKTOP_UNSIGNED_HAP:   libexec/"orca-app-unsigned.hap",
      ORCA_DESKTOP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      ORCA_DESKTOP_MODULE_ACL:     pkgshare/"module-acl.json",
      ORCA_DESKTOP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      PATH:                        tool_path
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "orca-app", "com.social4hyq.orca"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  test do
    # The launcher keeps state in ~/.config/orca-app; HOME is the test sandbox.
    ENV["HOME"] = testpath/"home"
    ENV["XDG_CONFIG_HOME"] = testpath/"home/.config"
    assert_match "Usage: orca-app", shell_output("#{bin}/orca-app --help")

    # Minimal stand-in HAP: the installer only rewrites config.json and swaps
    # module.json.
    fake_hap = testpath/"shell.hap"
    hap_tree = testpath/"hap-tree"
    (hap_tree/"resources/resfile/resources/app").mkpath
    fake_module = { "name" => "electron", "requestPermissions" => [
      { "name" => "ohos.permission.INTERNET" },
      { "name" => "ohos.permission.MICROPHONE" },
    ] }
    (hap_tree/"module.json").write JSON.generate(
      "app"    => { "bundleName" => "com.social4hyq.orca" },
      "module" => fake_module,
    )
    (hap_tree/"resources/resfile/resources/app/config.json").write '{"port":0,"orca":"","host":{}}'
    cd hap_tree do
      system "zip", "-q", "-X", fake_hap.to_s, "module.json",
             "resources/resfile/resources/app/config.json"
    end

    fake_bin = testpath/"bin"
    fake_bin.mkpath
    installer_args = testpath/"hap-installer-args"
    injected_copy = testpath/"injected.hap"
    hdc_log = testpath/"hdc-log"

    (fake_bin/"hdc").write <<~SH
      #!/bin/sh
      printf '%s\\n' "$*" >> #{hdc_log}
      case "$*" in
        *"list targets -v"*) printf '%s\\n' "127.0.0.1:34561  Connected" ;;
      esac
    SH
    chmod 0755, fake_bin/"hdc"

    (fake_bin/"app-installer").write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{installer_args}
      while [ $# -gt 0 ]; do
        case "$1" in
          --hap) cp "$2" #{injected_copy}; shift 2 ;;
          --signed-hap) printf 'signed-by-fake' > "$2"; shift 2 ;;
          *) shift ;;
        esac
      done
    SH
    chmod 0755, fake_bin/"app-installer"

    ENV.prepend_path "PATH", fake_bin

    host_config = testpath/"host-config.json"
    host_config.write JSON.generate(
      "port" => 6799,
      "orca" => "/opt/homebrew/bin/orca",
      "host" => {
        "home" => "/home/tester",
        "path" => "/opt/homebrew/bin:/usr/bin:/bin",
      },
    )
    assert_match "installed",
                 shell_output("#{bin}/orca-app install --hap #{fake_hap} --config #{host_config} --no-serve")
    injected_config = JSON.parse(
      shell_output("unzip -p #{injected_copy} resources/resfile/resources/app/config.json"),
    )
    assert_equal 6799, injected_config.fetch("port")
    assert_equal "/opt/homebrew/bin/orca", injected_config.fetch("orca")
    assert_equal "/home/tester", injected_config.dig("host", "home")
    refute injected_config.fetch("host").key?("dataRoot")
    refute injected_config.key?("url")

    module_json = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    acl_permissions = module_json.dig("module", "requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.MICROPHONE ohos.permission.READ_PASTEBOARD ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_permissions.sort
    assert_equal "acl\n", (testpath/"home/.config/orca-app/installed.mode").read
    refute_path_exists Pathname.new(Dir.home)/".hap-installer"
    installer = installer_args.read.lines(chomp: true)
    assert_equal "com.social4hyq.orca", installer[installer.index("--bundle-id") + 1]
    assert_equal "Orca", installer[installer.index("--app-name") + 1]
    assert_equal "electron", installer[installer.index("--module") + 1]
    assert_equal "EntryAbility", installer[installer.index("--ability") + 1]
    assert_match "installed",
                 shell_output("#{bin}/orca-app install --hap #{fake_hap} --config #{host_config} --no-acl --no-serve")
    strong_permissions = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
                             .dig("module", "requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.INTERNET ohos.permission.MICROPHONE], strong_permissions

    keep_tmp = testpath/"keep-tmp"
    keep_tmp.mkpath
    ENV["TMPDIR"] = keep_tmp.to_s
    keep_output = shell_output(
      "#{bin}/orca-app install --hap #{fake_hap} --config #{host_config} --keep --no-serve 2>&1",
    )
    assert_match "signed HAP kept at #{keep_tmp}/orca-app-signed.hap", keep_output
    assert_match "installed", keep_output
    assert_equal "signed-by-fake", (keep_tmp/"orca-app-signed.hap").read
    assert_equal "acl\n", (testpath/"home/.config/orca-app/installed.mode").read
    refute_match "signed HAP kept",
                 shell_output("#{bin}/orca-app install --hap #{fake_hap} --config #{host_config} --no-serve 2>&1")

    (testpath/"hdc-log").write("")
    with_env("HAP_INSTALLER_NO_START" => "1") do
      shell_output("#{bin}/orca-app install --hap #{fake_hap} --config #{host_config}")
    end
    refute_match(/aa start/, (testpath/"hdc-log").read)

    # uninstall goes through app-installer and keeps the app's data by default;
    # --purge deletes it, --device/HDC_TARGET pick the hdc target.
    shell_output("#{bin}/orca-app uninstall")
    assert_equal %w[uninstall --bundle-id com.social4hyq.orca], installer_args.read.lines(chomp: true)
    shell_output("#{bin}/orca-app uninstall --purge --device tablet-1")
    assert_equal %w[uninstall --bundle-id com.social4hyq.orca --device tablet-1 --purge],
                 installer_args.read.lines(chomp: true)
    with_env("HDC_TARGET" => "env-device") do
      shell_output("#{bin}/orca-app uninstall")
    end
    assert_equal %w[uninstall --bundle-id com.social4hyq.orca --device env-device],
                 installer_args.read.lines(chomp: true)
    assert_match "uninstall", shell_output("#{bin}/orca-app --help")

    # start takes --device and addresses the hdc target.
    ENV["ORCA_DESKTOP_HDC"] = "hdc"
    File.write(testpath/"hdc-log", "")
    shell_output("#{bin}/orca-app start --device tablet-1")
    assert_match(/-t tablet-1 shell aa start .*-b com\.social4hyq\.orca/, (testpath/"hdc-log").read)

    (testpath/"home/.config/orca-app").mkpath
    (testpath/"home/.config/orca-app/config.json").write JSON.generate("port" => free_port)

    assert_match "no managed server running", shell_output("#{bin}/orca-app stop")
    assert_match "not healthy", shell_output("#{bin}/orca-app status 2>&1", 1)

    # A healthy server without a pairing file (as the shell's own runtime) is
    # reported as healthy with exit status 0.
    up_port = free_port
    state_dir = testpath/"home/.config/orca-app"
    (testpath/"home/.config/orca-app/config.json").delete
    (testpath/"home/.config/orca-app/config.json").write JSON.generate("port" => up_port)
    web = spawn(formula_opt_bin("node")/"node", "-e",
                "require('http').createServer((q, r) => { r.statusCode = q.url === '/web-index.html' ? 200 : 404; " \
                "r.end('ok'); }).listen(#{up_port}, '127.0.0.1')",
                [:out, :err] => File::NULL)
    begin
      60.times do
        TCPSocket.new("127.0.0.1", up_port).close
        break
      rescue Errno::ECONNREFUSED
        sleep 0.25
      end
      assert_match "healthy at http://127.0.0.1:#{up_port}", shell_output("#{bin}/orca-app status 2>&1")

      # Installing while `orca-app serve` is running keeps its port, so the shell
      # attaches to that runtime instead of starting a second one next to it.
      (state_dir/"server.pid").write "#{web}\n"
      ready_record = { "type" => "orca_server_ready", "endpoint" => "ws://127.0.0.1:#{up_port}" }
      (state_dir/"server.ready.json").write JSON.generate(ready_record)
      assert_match "installed", shell_output("#{bin}/orca-app install --hap #{fake_hap} --no-serve")
      baked = JSON.parse(shell_output("unzip -p #{injected_copy} resources/resfile/resources/app/config.json"))
      assert_equal up_port, baked.fetch("port")

      # A pid file that points at a dead process does not pin the port.
      (state_dir/"server.pid").atomic_write "2147483646\n"
      assert_match "installed", shell_output("#{bin}/orca-app install --hap #{fake_hap} --no-serve")
      baked = JSON.parse(shell_output("unzip -p #{injected_copy} resources/resfile/resources/app/config.json"))
      refute_equal up_port, baked.fetch("port")
    ensure
      Process.kill("TERM", web)
      Process.wait(web)
      [state_dir/"server.pid", state_dir/"server.ready.json"].each { |file| file.delete if file.exist? }
    end

    # `serve` explains a startup failure caused by the data root's lock, and
    # `--reclaim` removes a stale lock only when its holder is provably gone. The
    # runtime, `ps` and /proc are fakes, so nothing here touches real processes.
    data_root = testpath/"orca-data"
    data_root.mkpath
    lock = data_root/"orcad.lock"
    fake_proc = testpath/"fake-proc"
    fake_proc.mkpath
    fake_ps = testpath/"fake-ps"
    fake_ps.write "#!/bin/sh\ncat #{testpath}/ps-output\n"
    chmod 0755, fake_ps
    (testpath/"ps-output").write "  PID ARGS\n    1 /bin/sh\n"
    (state_dir/"config.json").atomic_write JSON.generate("port" => free_port)
    write_lock = lambda do |pid, identity|
      lock.atomic_write JSON.generate("pid" => pid, "identity" => identity, "role" => "orcad")
    end
    fake_runtime = lambda do |failure|
      fake_node = testpath/"fake-orcad-node"
      fake_node.atomic_write <<~SH
        #!/bin/sh
        [ "$1" = "-e" ] && exec #{formula_opt_bin("node")}/node "$@"
        echo "orcad: failed to start: #{failure}" >&2
        exit 1
      SH
      chmod 0755, fake_node
      fake_node
    end
    serve = lambda do |*args, failure: "{ code: 'other_failure' }"|
      with_env(ORCA_DESKTOP_NODE: fake_runtime.call(failure).to_s, ORCA_DESKTOP_DATA: data_root.to_s,
               ORCA_DESKTOP_PS: fake_ps.to_s, ORCA_DESKTOP_PROC_ROOT: fake_proc.to_s) do
        shell_output("#{bin}/orca-app serve #{args.join(" ")} 2>&1", 1)
      end
    end

    write_lock.call(2_147_483_646, "20020262")
    output = serve.call(failure: "{ code: 'orcad_instance_lock_foreign_identity' }")
    assert_match "locked by another identity (uid 20020262, pid 2147483646)", output
    assert_match "orca-app serve --reclaim", output
    refute_match "failed to start", output

    output = serve.call(failure: "{ code: 'orcad_instance_lock_holder_unverifiable' }")
    assert_match "cannot prove that here", output
    assert_match "orca-app serve --reclaim", output

    assert_match "failed to start: { code: 'other_failure' }", serve.call
    refute_match "--reclaim", serve.call

    # The lock names a live pid: refuse and keep the lock.
    (fake_proc/"2147483646").mkpath
    assert_match "still running", serve.call("--reclaim")
    assert_path_exists lock
    (fake_proc/"2147483646").rmdir

    # An orcad runtime is running anywhere: refuse, keep the lock and name the
    # process. The list is read without a pipe into `grep -q`, which pipefail
    # would turn into "not running" through SIGPIPE; the long line makes the
    # output larger than a pipe buffer.
    orcad = "node /x/orcad/orcad-server.js --port 1"
    (testpath/"ps-output").atomic_write "  PID ARGS\n    2 #{"x" * 70_000}\n 4242 #{orcad}\n"
    output = serve.call("--reclaim")
    assert_match "an orcad process is running; not removing the lock of pid 2147483646", output
    assert_match "4242 #{orcad}", output
    assert_path_exists lock

    # At most three are listed, the rest is counted; an absolute path to node counts.
    (testpath/"ps-output").atomic_write <<~PS
      4242 #{orcad}
      4243 /usr/bin/node /x/orcad/orcad-server.js --port 2
      4244 #{orcad}
      4245 #{orcad}
    PS
    output = serve.call("--reclaim")
    assert_match "4243 /usr/bin/node", output
    assert_match "... and 1 more", output
    refute_match "4245 node", output
    assert_path_exists lock

    # Processes that only mention the file name are not runtimes and do not block.
    (testpath/"ps-output").atomic_write <<~PS
      PID ARGS
      10 vim notes-about-orcad-server.txt
      11 sh -c ps -eo args | grep orcad-server
      12 python3 -c pass /x/orcad/orcad-server.js
      13 vim /x/orcad/orcad-server.js
    PS

    # Holder gone and no runtime running: the lock is removed, then startup proceeds.
    output = serve.call("--reclaim")
    assert_match "removed the stale lock of pid 2147483646 (identity 20020262)", output
    refute_path_exists lock

    # Without a lock there is nothing to reclaim.
    assert_match "nothing to reclaim", serve.call("--reclaim")

    saved_home = Dir.home
    saved_xdg = ENV.fetch("XDG_CONFIG_HOME", nil)
    ENV["HOME"] = (testpath/"home2").to_s
    ENV["XDG_CONFIG_HOME"] = (testpath/"xdg2").to_s
    old_port = free_port
    (testpath/"xdg2/orca-app").mkpath
    (testpath/"xdg2/orca-app/config.json").write JSON.generate("port" => old_port)
    (testpath/"xdg2/orca-app/installed.mode").write "no-acl\n"
    moved = shell_output("#{bin}/orca-app status 2>&1", 1)
    assert_match "moved the state from #{testpath}/xdg2/orca-app to #{testpath}/home2/.config/orca-app", moved
    assert_match "not healthy at http://127.0.0.1:#{old_port}", moved
    assert_equal old_port, JSON.parse((testpath/"home2/.config/orca-app/config.json").read).fetch("port")
    assert_equal "no-acl\n", (testpath/"home2/.config/orca-app/installed.mode").read
    refute_path_exists testpath/"xdg2/orca-app/config.json"
    assert_path_exists testpath/"xdg2/orca-app/config.json.migrated"
    ENV.delete("XDG_CONFIG_HOME")
    found = shell_output("#{bin}/orca-app status 2>&1", 1)
    assert_match "not healthy at http://127.0.0.1:#{old_port}", found
    refute_match "moved the state", found
    ENV["XDG_CONFIG_HOME"] = (testpath/"xdg2").to_s
    (testpath/"xdg2/orca-app/config.json").write JSON.generate("port" => free_port)
    ignored = shell_output("#{bin}/orca-app status 2>&1", 1)
    assert_match "already has a config", ignored
    assert_match "not healthy at http://127.0.0.1:#{old_port}", ignored
    assert_path_exists testpath/"xdg2/orca-app/config.json.superseded"
    refute_path_exists testpath/"xdg2/orca-app/config.json"
    refute_match "already has a config", shell_output("#{bin}/orca-app status 2>&1", 1)
    ENV["HOME"] = saved_home
    ENV["XDG_CONFIG_HOME"] = saved_xdg

    hap = libexec/"orca-app-unsigned.hap"
    assert_match "libs/arm64-v8a/libelectron.so", shell_output("unzip -Z1 #{hap}")
    assert_match "resources/resfile/resources/app/attach.cjs", shell_output("unzip -Z1 #{hap}")
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    system "node", "--check", tap_root/"Resources/orca-app/app/main.cjs"
    tests = tap_root/"Resources/orca-app/tests"
    system "node", "--test", tests/"attach.test.cjs", tests/"close-handler.test.cjs", tests/"cli-env.test.cjs",
           tests/"relay.test.cjs", tests/"shell-flow.test.cjs"
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_equal 0, placeholder.fetch("port")
    refute placeholder.key?("url")
    permissions = JSON.parse(shell_output("unzip -p #{hap} module.json"))
                      .fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.MICROPHONE], permissions.sort
    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_requested = acl.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.MICROPHONE ohos.permission.READ_PASTEBOARD ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_requested.sort
    system "unzip", "-tq", hap
  end
end
