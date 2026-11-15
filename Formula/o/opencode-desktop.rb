class OpencodeDesktop < Formula
  desc "Desktop shell for the OpenCode agent (Electron window on local opencode serve)"
  homepage "https://opencode.ai"
  url "https://github.com/social4hyq/homebrew-core/releases/download/opencode-desktop-v0.1.3/opencode-desktop-0.1.3.tar.gz"
  sha256 "662d2636c88ec63a105bcce3b044f2c720ef5750ce7d60e431e95badbe328ea1"
  # Tap-authored shell scripts (MIT) packaging the openharmony-sig Electron
  # prebuilt (Chromium/Electron, mixed MIT/BSD/LGPL); see multica.rb.
  license :cannot_represent

  livecheck do
    skip "Tap-hosted payload, versioned with the formula"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/opencode-desktop-v0.1.3-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cc2ad0207edf0df92e23d9aa2d6753cb40e0cd06228a7880727a82b525c7c9b7"
  end

  depends_on "node" => :build
  depends_on "curl"
  depends_on "hap-installer"
  depends_on "ohos-sdk-toolchains"
  depends_on "opencode"
  depends_on "zip"

  # openharmony-sig/electron PC(2in1) prebuilt (CodeHub mirror hosted on this
  # tap's release; redistribution assumed by the tap owner, see multica.rb).
  resource "electron-ohos" do
    url "https://github.com/social4hyq/homebrew-core/releases/download/electron-ohos-v34.9.0-20261030.1/v34.9.0-20261030.1-release.zip"
    sha256 "599e97b3d8b1e5071a2387496104b443e58079a5f5c165b0114e65ffc601df3a"
  end

  def install
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_132.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    %w[main.cjs package.json config.json waiting.html].each do |name|
      cp buildpath/"app"/name, app/name
    end

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.opencodedesktop"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp buildpath/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    # App name and ability labels live in per-locale string resources: patching
    # only the base file leaves the zh_CN/en_US overrides intact and the
    # launcher keeps showing the template's "Electron" label, so glob every
    # locale directory.
    (shell.glob("AppScope/resources/*/element/string.json") +
     shell.glob("electron/src/main/resources/*/element/string.json")).each do |file|
      strings = JSON.parse(file.read)
      strings.fetch("string").each do |entry|
        case entry["name"]
        when "app_name", "EntryAbility_label" then entry["value"] = "OpenCode"
        end
      end
      rm file
      file.write JSON.pretty_generate(strings) + "\n"
    end

    # CI's electron-ohos-ci CLT carries an NDK-less SDK subset (no llvm-strip);
    # mirror the multica packaging deltas that keep hvigor away from the strip
    # task and from signing material the container does not have.
    inreplace shell/"build-profile.json5", "        \"signingConfig\": \"default\",\n", ""
    inreplace shell/"electron/src/main/module.json5", "    \"mainElement\": \"EntryAbility\",\n",
              "    \"mainElement\": \"EntryAbility\",\n    \"extractNativeLibs\": true,\n"

    # Restricted permissions (pasteboard, location, ...) cannot be granted with
    # local auto-signing; the shell only needs loopback HTTP, and this trim
    # installs under local auto-signing.
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
      odie "opencode-desktop builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['opencode-desktop']"
    end

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
                    "opencode-desktop-unsigned.hap"

    # The default HAP requests only what local automatic signing can grant
    # without ACLs. `opencode-desktop install` swaps in this variant (which
    # also requests the two ACL-gated permissions) when it can prepare an
    # ACL-capable signing profile, so the shell may start `opencode serve`
    # itself and reach the host user files.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"opencode-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    pkgshare.install buildpath/"scripts/install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    libexec.install buildpath/"scripts/opencode-desktop.sh"
    chmod 0755, libexec/"opencode-desktop.sh"
    (bin/"opencode-desktop").write_env_script libexec/"opencode-desktop.sh",
      OPENCODE_DESKTOP_UNSIGNED_HAP:   libexec/"opencode-desktop-unsigned.hap",
      OPENCODE_DESKTOP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      OPENCODE_DESKTOP_MODULE_ACL:     pkgshare/"module-acl.json",
      OPENCODE_DESKTOP_OPENCODE_BIN:   formula_opt_bin("opencode")/"opencode",
      PATH:                            "#{formula_opt_bin("opencode")}:$PATH"
  end

  def caveats
    <<~EOS
      The desktop HAP is unsigned in the bottle. Connect and unlock the device,
      then run `opencode-desktop install`. hap-installer handles Huawei
      Developer login, local debug profile generation, signing, installation,
      and launch.

      The shell starts its local `opencode serve` instance itself on launch and
      shares the sessions of the opencode TUI. This needs the weak-sandbox
      permissions CUSTOM_SANDBOX and READ_WRITE_USER_FILE, which are granted
      through a debug profile generated on the spot (no approval wait; the
      release path still goes through AGC review). When the system command
      line toolchain is missing, install falls back to the strong-sandbox HAP
      and the shell then waits for `opencode-desktop serve`.
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "Usage: opencode-desktop", shell_output("#{bin}/opencode-desktop --help")

    # Install runs first on a fresh HOME (it must create config.json itself)
    # and exercises config/ACL injection, signing-project patching, signing
    # and chunked hdc installation with fake devecocli / hap-installer-sign /
    # hdc and a minimal CLT source. The fake signer writes a tiny result; the
    # script's own trap then removes the staging.
    fake_bin = testpath/"bin"
    fake_bin.mkpath
    injected_copy = testpath/"injected.hap"
    signer_args = testpath/"hap-installer-sign-args"
    hdc_log = testpath/"hdc-log"
    clt_env = testpath/"clt-env"

    fake_devecocli = fake_bin/"devecocli"
    fake_devecocli.write <<~SH
      #!/bin/sh
      case "$1" in
        auth|signature) exit 0 ;;
        create)
          while [ $# -gt 0 ]; do
            if [ "$1" = "--project-path" ]; then project="$2"; fi
            shift
          done
          mkdir -p "$project/entry/src/main"
          printf '{\\n  "module": {\\n    "name": "entry",\\n    "type": "entry"\\n  }\\n}\\n' > "$project/entry/src/main/module.json5"
          printf '{"app":{"signingConfigs":[]}}\\n' > "$project/build-profile.json5"
          ;;
      esac
    SH
    chmod 0755, fake_devecocli

    fake_signer = fake_bin/"hap-installer-sign"
    fake_signer.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{signer_args}
      printf '%s\\n' "${COMMAND_LINE_TOOL_PATH:-}" > #{clt_env}
      out=""
      while [ $# -gt 0 ]; do
        case "$1" in
          --hap) cp "$2" #{injected_copy}; shift 2 ;;
          --output) out="$2"; shift 2 ;;
          *) shift ;;
        esac
      done
      printf 'signed' > "$out"
    SH
    chmod 0755, fake_signer

    fake_hdc = fake_bin/"hdc"
    fake_hdc.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" >> #{hdc_log}
      case "$*" in
        *"bm install"*) printf '%s\\n' "install bundle successfully" ;;
      esac
    SH
    chmod 0755, fake_hdc

    clt_src = testpath/"clt-src"
    (clt_src/"sdk/default/openharmony/toolchains/lib").mkpath
    (clt_src/"sdk/default/openharmony/toolchains/hdc").write "#!/bin/sh\nexit 0\n"
    (clt_src/"sdk/default/openharmony/toolchains/lib/PermissionDefinitions.json").write "{}"
    (clt_src/"sdk/default/openharmony/toolchains/lib/hap-sign-tool").write "#!/bin/sh\nexit 0\n"
    (clt_src/"sdk/default/hms").mkpath
    (clt_src/"sdk/default/hms/uni-package.json").write "{}"
    (clt_src/"hvigor/bin").mkpath
    (clt_src/"hvigor/bin/hvigorw.js").write ""
    (clt_src/"ohpm/bin").mkpath
    (clt_src/"ohpm/bin/pm-cli.js").write ""
    (clt_src/"node/bin").mkpath
    (clt_src/"node/bin/node").write "#!/bin/sh\nexit 0\n"
    (clt_src/"sdk/default/sdk-pkg.json").write "{}"
    clt_cache = testpath/"clt-cache"

    ENV.prepend_path "PATH", fake_bin
    ENV["OPENCODE_DESKTOP_CLT"] = clt_src.to_s
    ENV["OPENCODE_DESKTOP_CLT_CACHE"] = clt_cache.to_s

    assert_match "installed and started", shell_output("#{bin}/opencode-desktop install")
    config = JSON.parse(shell_output("unzip -p #{injected_copy} resources/resfile/resources/app/config.json"))
    assert_operator config.fetch("port"), :>, 0
    refute_empty config.fetch("password")
    refute_empty config.fetch("opencode")
    assert_equal Dir.home, config.dig("host", "home")
    acl_module = JSON.parse(shell_output("unzip -p #{injected_copy} module.json"))
    acl_requested = acl_module.fetch("module").fetch("requestPermissions")
    acl_permissions = acl_requested.map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO
                    ohos.permission.INTERNET ohos.permission.READ_WRITE_USER_FILE],
                 acl_permissions.sort
    project_dir = Pathname.new(Dir.home)/".hap-installer/projects/com.social4hyq.opencodedesktop"
    assert_match "CUSTOM_SANDBOX", (project_dir/"entry/src/main/module.json5").read
    signer = signer_args.read.lines(chomp: true)
    assert_equal (project_dir/"build-profile.json5").to_s, signer[signer.index("--profile") + 1]
    assert_match "aa start -a EntryAbility -b com.social4hyq.opencodedesktop -m electron", hdc_log.read

    # Server orchestration against the real opencode binary (config already
    # exists from the install above).
    assert_match "serving at", shell_output("#{bin}/opencode-desktop serve")
    assert_match "healthy", shell_output("#{bin}/opencode-desktop status")
    assert_match "stopped", shell_output("#{bin}/opencode-desktop stop")

    # `start --serve-only` keeps a CLI backend; `start` just opens the app.
    serve_only_args = testpath/"hdc-start-args"
    fake_hdc.delete if fake_hdc.exist?
    fake_hdc.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{serve_only_args}
    SH
    chmod 0755, fake_hdc
    assert_match "serving at", shell_output("#{bin}/opencode-desktop start --serve-only")
    assert_match "opened", shell_output("#{bin}/opencode-desktop start")
    assert_equal %w[shell aa start -a EntryAbility -b com.social4hyq.opencodedesktop -m electron],
                 serve_only_args.read.lines(chomp: true)
    assert_match "stopped", shell_output("#{bin}/opencode-desktop stop")

    hap = libexec/"opencode-desktop-unsigned.hap"
    assert_path_exists hap
    assert_path_exists pkgshare/"module-acl.json"
    listing = shell_output("unzip -l #{hap}")
    assert_match "pack.info", listing
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "resources/resfile/resources/app/main.cjs", listing
    assert_match "resources/resfile/resources/app/waiting.html", listing
    placeholder = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/config.json"))
    assert_equal 0, placeholder.fetch("port")
    profile = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    permissions = profile.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET], permissions.sort
    system "unzip", "-tq", hap
  end
end
