class ZcodeDesktop < Formula
  desc "Desktop shell for the ZCode agent (Electron window on a local zcode --web)"
  homepage "https://zcode.z.ai"
  # Same upstream pin as `zcode`: the shell only provides the window, the web
  # workbench comes from the installed CLI, so both formulae are versioned
  # against the same upstream snapshot.
  url "https://github.com/zai-org/ZCode.git",
      revision: "fec975905a2abd4c07e35c40d51fa097a2258ec9"
  version "3.18.2"
  # Tap-authored shell scripts (MIT) packaging the openharmony-sig Electron
  # prebuilt (Chromium/Electron, mixed MIT/BSD/LGPL); see multica.rb.
  license :cannot_represent

  livecheck do
    url "https://raw.githubusercontent.com/zai-org/ZCode/main/package.json"
    strategy :json do |json|
      json["version"]
    end
  end

  depends_on "node" => :build
  depends_on "curl"
  depends_on "hap-installer"
  depends_on "ohos-sdk-toolchains"
  depends_on "zcode"
  depends_on "zip"

  # Shell sources live in the tap so they are reviewable in the PR and no
  # opaque release payload is involved. Every path is listed literally: the
  # weekly remove-unused-patches job keeps files referenced from Formula/.
  SHELL_FILES = %w[
    Patches/zcode-desktop/app/config.json
    Patches/zcode-desktop/app/main.cjs
    Patches/zcode-desktop/app/package.json
    Patches/zcode-desktop/app/waiting.html
    Patches/zcode-desktop/assets/icon.png
    Patches/zcode-desktop/scripts/build-hap.sh
    Patches/zcode-desktop/scripts/install-desktop.sh
    Patches/zcode-desktop/scripts/stage-app.sh
    Patches/zcode-desktop/scripts/zcode-desktop.sh
  ].freeze

  # openharmony-sig/electron PC(2in1) prebuilt, v37 line (Chromium 138); see
  # multica.rb for the mirror/provenance notes.
  resource "electron-ohos" do
    url "https://github.com/social4hyq/homebrew-core/releases/download/electron-ohos-v37.2.1-20260429.5/v37.2.1-openharmony-arm64.zip"
    sha256 "2a1421f6219ac760092aecb4a82bf5ab49b19918f23edec5a9420d1b41eea9e8"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    source_root = tap_root/"Patches/zcode-desktop"
    SHELL_FILES.each do |file|
      raise "#{file} is missing from the tap" unless (tap_root/file).exist?
    end

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_138.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    %w[main.cjs package.json config.json waiting.html].each do |name|
      cp source_root/"app"/name, app/name
    end

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.zcodedesktop"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp source_root/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    # App name and ability labels live in per-locale string resources: patching
    # only the base file leaves the zh_CN/en_US overrides intact and the
    # launcher keeps showing the template's "Electron" label.
    (shell.glob("AppScope/resources/*/element/string.json") +
     shell.glob("electron/src/main/resources/*/element/string.json")).each do |file|
      strings = JSON.parse(file.read)
      strings.fetch("string").each do |entry|
        case entry["name"]
        when "app_name", "EntryAbility_label" then entry["value"] = "ZCode"
        end
      end
      rm file
      file.write JSON.pretty_generate(strings) + "\n"
    end

    # The v37 template embeds a signingConfigs block pointing at the vendor's
    # own certificate paths and targets 5.0.5(17); drop the signing material and
    # pin the target to the version this build image is known to build. The
    # file is strict JSON in this version, so rewrite it instead of inreplace.
    profile = JSON.parse((shell/"build-profile.json5").read)
    profile.fetch("app").fetch("products").each do |product|
      product.delete("signingConfig")
      product["compatibleSdkVersion"] = "6.0.0(20)"
    end
    profile.fetch("app").delete("signingConfigs")
    profile_file = shell/"build-profile.json5"
    rm profile_file
    profile_file.write JSON.pretty_generate(profile) + "\n"
    inreplace shell/"electron/src/main/module.json5", "    \"mainElement\": \"EntryAbility\",\n",
              "    \"mainElement\": \"EntryAbility\",\n    \"extractNativeLibs\": true,\n"

    # The shell only talks to the host service over loopback. Restricted
    # permissions (JIT, pasteboard) are added to the install-time ACL variant
    # instead of every install; see module-acl.json below.
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\n    \],/m,
              <<~JSON5.chomp
                "requestPermissions": [
                      { "name": "ohos.permission.INTERNET" },
                      { "name": "ohos.permission.GET_NETWORK_INFO" }
                    ],
              JSON5

    # HAP shell build. CI runs in the private electron-ohos-ci image (the
    # generic Electron-on-OHOS build image, selected via the
    # OHOS_CI_IMAGE_OVERRIDES repo variable), which bakes the HarmonyOS
    # command-line toolchain at /opt/electron-ohos-clt — repacked from a
    # licensed system CLT install, not publicly redistributable. The shell
    # compiles no C++, so the NDK-less SDK subset the image carries suffices.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "zcode-desktop builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['zcode-desktop']"
    end

    # brew's sanitized build env drops the container's LD_LIBRARY_PATH, but
    # ohos_packing_tool needs the SDK clang runtimes and the libhilog stderr
    # adapter baked into the image.
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    # A container inheriting RLIMIT_NOFILE near 1e9 drives the musl FD-table
    # sizing into a refused mapping; cap it for the hvigor process tree
    # (only ever lowering — never raise an environment's existing limit).
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    if hard_cap > 65_536
      Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536)
    end

    cd shell do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    libexec.install shell/"electron/build/default/outputs/default/electron-default-unsigned.hap" =>
                    "zcode-desktop-unsigned.hap"

    # The default install swaps in this module.json: the two kernel ACLs keep
    # the renderer out of --jitless (WebAssembly, so document previews and the
    # diff worker work) and READ_PASTEBOARD makes paste work. Everything else
    # stays out of the HAP so a local debug profile can grant it.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"zcode-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION
       ohos.permission.READ_PASTEBOARD].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # cp, not install: Pathname#install moves the source, and the tap checkout
    # is a read-only host mount inside the CI container.
    pkgshare.mkpath
    cp source_root/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    cp source_root/"scripts/zcode-desktop.sh", libexec/"zcode-desktop.sh"
    chmod 0755, libexec/"zcode-desktop.sh"
    (bin/"zcode-desktop").write_env_script libexec/"zcode-desktop.sh",
      ZCODE_DESKTOP_UNSIGNED_HAP:   libexec/"zcode-desktop-unsigned.hap",
      ZCODE_DESKTOP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      ZCODE_DESKTOP_MODULE_ACL:     pkgshare/"module-acl.json",
      ZCODE_DESKTOP_ZCODE:          formula_opt_bin("zcode")/"zcode",
      ZCODE_DESKTOP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc"
  end

  def caveats
    <<~EOS
      The desktop HAP is unsigned in the bottle. Connect and unlock the device,
      then run:

        zcode-desktop install

      hap-installer generates a local debug profile (the first run asks for a
      Huawei Developer login), signs the HAP and installs it.

      The shell connects to the host `zcode --web` instance and never starts
      it itself:

        zcode-desktop serve      # start it (the shell waits for it otherwise)
        zcode-desktop status
        zcode-desktop stop

      `serve` also creates ~/.zcode/v2/credential-secret and exports
      ZCODE_CREDENTIAL_SECRET_FILE. ZCode 3.18.2 refuses to start without a
      credential secret and HarmonyOS has no Secret Service, so the file is
      required even when no Z.ai account is used.

      The default install carries the two kernel ACLs (JIT/WebAssembly for the
      renderer) and READ_PASTEBOARD; `zcode-desktop install --no-acl` installs
      the strong-sandbox variant instead (no JIT, no paste). 坚盾守护模式
      disables JIT regardless of the ACLs. The workbench's embedded terminal is
      unavailable because node-pty cannot spawn child processes under bun on
      HarmonyOS.
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    ENV.delete("XDG_CONFIG_HOME")
    assert_match "Usage: zcode-desktop", shell_output("#{bin}/zcode-desktop --help")

    # A minimal stand-in for the shell HAP: the installer only rewrites
    # config.json (and swaps module.json for the ACL variant), so the 200 MB
    # artifact does not need to be copied around in the test.
    fake_hap = testpath/"shell.hap"
    hap_tree = testpath/"hap-tree"
    (hap_tree/"resources/resfile/resources/app").mkpath
    fake_module = { "name" => "electron", "requestPermissions" => [{ "name" => "ohos.permission.INTERNET" }] }
    (hap_tree/"module.json").write JSON.generate(
      "app"    => { "bundleName" => "com.social4hyq.zcodedesktop" },
      "module" => fake_module,
    )
    (hap_tree/"resources/resfile/resources/app/config.json").write '{"port":0}'
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
      printf '%s\n' "$*" >> #{hdc_log}
      case "$*" in
        *"list targets -v"*) printf '%s\n' "127.0.0.1:34561  Connected" ;;
      esac
    SH
    chmod 0755, fake_bin/"hdc"

    (fake_bin/"hap-installer").write <<~SH
      #!/bin/sh
      printf '%s\n' "$@" > #{installer_args}
      while [ $# -gt 0 ]; do
        case "$1" in
          --hap) cp "$2" #{injected_copy}; shift 2 ;;
          *) shift ;;
        esac
      done
    SH
    chmod 0755, fake_bin/"hap-installer"

    (fake_bin/"devecocli").write <<~SH
      #!/bin/sh
      case "$1" in
        create)
          while [ $# -gt 0 ]; do
            if [ "$1" = "--project-path" ]; then project="$2"; fi
            shift
          done
          mkdir -p "$project/entry/src/main"
          printf '{\n  "module": {\n    "name": "entry",\n    "type": "entry"\n  }\n}\n' > "$project/entry/src/main/module.json5"
          printf '{"app":{"signingConfigs":[]}}\n' > "$project/build-profile.json5"
          ;;
      esac
    SH
    chmod 0755, fake_bin/"devecocli"

    ENV.prepend_path "PATH", fake_bin
    ENV["ZCODE_DESKTOP_HDC"] = (fake_bin/"hdc").to_s

    # Default install: config injection, ACL module and signing project.
    assert_match "installed and started", shell_output("#{bin}/zcode-desktop install --hap #{fake_hap}")
    host_config = JSON.parse((testpath/"home/.config/zcode-desktop/config.json").read)
    assert_operator host_config.fetch("port"), :>, 0
    assert_equal Dir.home, host_config.fetch("workspace")
    assert_path_exists testpath/"home/.zcode/v2/credential-secret"
    injected_config = JSON.parse(
      shell_output("unzip -p #{injected_copy} resources/resfile/resources/app/config.json"),
    )
    assert_equal host_config.fetch("port"), injected_config.fetch("port")
    assert_equal Dir.home, injected_config.fetch("workspace")
    acl_module = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    acl_permissions = acl_module.dig("module", "requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.READ_PASTEBOARD
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_permissions.sort
    project_dir = Pathname.new(Dir.home)/".hap-installer/projects/com.social4hyq.zcodedesktop"
    assert_match "READ_PASTEBOARD", (project_dir/"entry/src/main/module.json5").read
    installer = installer_args.read.lines(chomp: true)
    assert_equal "com.social4hyq.zcodedesktop", installer[installer.index("--bundle-id") + 1]
    assert_equal "ZCode", installer[installer.index("--app-name") + 1]
    assert_equal "electron", installer[installer.index("--module") + 1]
    assert_equal "EntryAbility", installer[installer.index("--ability") + 1]

    # --no-acl keeps the HAP's own permission list.
    assert_match "installed and started",
                 shell_output("#{bin}/zcode-desktop install --hap #{fake_hap} --no-acl")
    strong_module = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    strong_requests = strong_module.dig("module", "requestPermissions")
    strong_permissions = strong_requests.map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.INTERNET], strong_permissions

    assert_match "no managed server running", shell_output("#{bin}/zcode-desktop stop")
    assert_match "not healthy", shell_output("#{bin}/zcode-desktop status", 1)

    # The real bottle HAP.
    hap = libexec/"zcode-desktop-unsigned.hap"
    assert_path_exists hap
    listing = shell_output("unzip -l #{hap}")
    assert_match "pack.info", listing
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "resources/resfile/resources/app/main.cjs", listing
    assert_match "resources/resfile/resources/app/waiting.html", listing
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_equal 0, placeholder.fetch("port")
    permissions = JSON.parse(shell_output("unzip -p #{hap} module.json"))
                      .fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_requested = acl.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET
                    ohos.permission.READ_PASTEBOARD
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_requested.sort
    system "unzip", "-tq", hap
  end
end
