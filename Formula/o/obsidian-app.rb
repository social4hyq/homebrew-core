class ObsidianApp < Formula
  desc "Notes desktop for HarmonyOS PC running the official Obsidian package"
  homepage "https://obsidian.md"
  url "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.15.1/obsidian-1.15.1.asar.gz"
  sha256 "3f6808c14204063349d5a7a59b9f2f637958063fa85eeebe767e13e06d314c0f"
  # The url is the vendor package, so version and autobump follow Obsidian; the
  # host payload in Resources/obsidian-app is version-independent. The asar is
  # fetched at install time and never put in the bottle.
  license :cannot_represent
  revision 11

  # desktop-releases.json carries the latest desktop version, asar URL and
  # sha256.
  livecheck do
    url "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json"
    strategy :json do |json|
      json["latestVersion"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/obsidian-app-v1.15.1-r13"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "927c449fa1fa12ae74381ee7e5a230bbc1162c04184c11353bbe39a15616888c"
  end

  depends_on "app-installer"
  depends_on "curl"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"
  depends_on "zip"

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/install-lib.sh
    Resources/obsidian-app/app/bootstrap.cjs
    Resources/obsidian-app/app/node_modules/@electron/remote/LICENSE
    Resources/obsidian-app/app/node_modules/@electron/remote/README.md
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/common/get-electron-binding.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/common/get-electron-binding.js
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/common/ipc-messages.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/common/ipc-messages.js
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/common/module-names.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/common/module-names.js
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/common/type-utils.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/common/type-utils.js
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/main/index.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/main/index.js
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/main/objects-registry.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/main/objects-registry.js
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/main/server.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/main/server.js
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/callbacks-registry.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/callbacks-registry.js
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/index.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/index.js
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/remote.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/remote.js
    Resources/obsidian-app/app/node_modules/@electron/remote/index.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/main/index.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/main/index.js
    Resources/obsidian-app/app/node_modules/@electron/remote/package.json
    Resources/obsidian-app/app/node_modules/@electron/remote/renderer/index.d.ts
    Resources/obsidian-app/app/node_modules/@electron/remote/renderer/index.js
    Resources/obsidian-app/app/package.json
    Resources/obsidian-app/assets/icon.png
    Resources/obsidian-app/assets/icon32.png
    Resources/obsidian-app/scripts/install-desktop.sh
    Resources/obsidian-app/scripts/obsidian-cli.cjs
    Resources/obsidian-app/scripts/obsidian-desktop.sh
  ].freeze

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/obsidian-app"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    # Host payload only (bootstrap + @electron/remote); the vendor asar is
    # injected at install time.
    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    cp res/"app/bootstrap.cjs", app/"bootstrap.cjs"
    cp res/"app/package.json", app/"package.json"
    cp_r res/"app/node_modules", app/"node_modules"

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.obsidiandesktop"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    # Locale overrides would otherwise keep the Electron launcher label.
    (shell.glob("AppScope/resources/*/element/string.json") +
     shell.glob("electron/src/main/resources/*/element/string.json")).each do |file|
      strings = JSON.parse(file.read)
      strings.fetch("string").each do |entry|
        case entry["name"]
        when "app_name", "EntryAbility_label" then entry["value"] = "Obsidian"
        end
      end
      rm file
      file.write JSON.pretty_generate(strings) + "\n"
    end

    # Brand from the vendor icon (assets/ from the official tarball); the
    # template ships the Electron/OpenCode icons.
    %w[app_icon.png startIcon.png].each do |name|
      cp res/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    cp res/"assets/icon32.png", shell/"AppScope/resources/base/media/product_logo_32.png"

    # Normalize CRLF so exact replacements and the deep-link insertion match.
    [
      shell/"build-profile.json5",
      shell/"electron/src/main/module.json5",
      shell/"electron/src/main/ets/entryability/EntryAbility.ets",
      shell/"web_engine/src/main/module.json5",
    ].each do |file|
      text = file.read
      file.atomic_write(text.gsub("\r\n", "\n")) if text.include?("\r\n")
    end

    # The CI SDK lacks llvm-strip and local signing material.
    inreplace shell/"build-profile.json5", "        \"signingConfig\": \"default\",\n", ""
    inreplace shell/"electron/src/main/module.json5", "    \"mainElement\": \"EntryAbility\",\n",
              "    \"mainElement\": \"EntryAbility\",\n    \"extractNativeLibs\": true,\n"

    module_file = shell/"electron/src/main/module.json5"
    module_text = module_file.read
    link_skill = [
      "          {",
      "            \"actions\": [",
      "              \"ohos.want.action.viewData\"",
      "            ],",
      "            \"uris\": [",
      "              {",
      "                \"scheme\": \"link\"",
      "              }",
      "            ]",
      "          }",
    ].join("\n")
    obsidian_skill = link_skill.sub("\"scheme\": \"link\"", "\"scheme\": \"obsidian\"")
    needle = link_skill + "\n        ],"
    unless module_text.include?(needle)
      raise "obsidian-desktop: cannot find the link skill in module.json5"
    end

    module_file.atomic_write(module_text.sub(needle, link_skill + ",\n" + obsidian_skill + "\n        ],"))

    entry_ability = shell/"electron/src/main/ets/entryability/EntryAbility.ets"
    entry_text = entry_ability.read
    unless entry_text.sub!("import Want from '@ohos.app.ability.Want';",
                           "import fs from '@ohos.file.fs';\nimport Want from '@ohos.app.ability.Want';")
      raise "obsidian-desktop: cannot find the Want import in EntryAbility.ets"
    end

    old_method = [
      "  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {",
      "    super.onCreate(want, launchParam);",
      "  }",
    ].join("\n")
    new_method = [
      "  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {",
      "    // Cold-start deep link: the runtime does not expose want.uri to Electron",
      "    // on the first launch, so persist it for the HAP host to replay.",
      "    const launchUri = want ? (want['uri'] as string) : undefined;",
      "    if (typeof launchUri === 'string' && launchUri.includes('://') &&",
      "      !launchUri.startsWith('file://')) {",
      "      try {",
      "        const appFilesDir = this.context.getApplicationContext().filesDir;",
      "        const file = fs.openSync(appFilesDir + '/incoming-uris.txt',",
      "          fs.OpenMode.CREATE | fs.OpenMode.APPEND | fs.OpenMode.WRITE_ONLY);",
      "        fs.writeSync(file.fd, launchUri + '\\n');",
      "        fs.closeSync(file);",
      "      } catch (error) {",
      "        console.error('failed to record launch uri: ' + JSON.stringify(error));",
      "      }",
      "    }",
      "    super.onCreate(want, launchParam);",
      "  }",
    ].join("\n")
    unless entry_text.sub!(old_method, new_method)
      raise "obsidian-desktop: cannot find EntryAbility.onCreate"
    end

    entry_ability.atomic_write(entry_text)

    # The strong-sandbox shell only needs network; vaults stay in the app
    # sandbox.
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\n    \],/m,
              <<~JSON5.chomp
                "requestPermissions": [
                      { "name": "ohos.permission.INTERNET" },
                      { "name": "ohos.permission.GET_NETWORK_INFO" }
                    ],
              JSON5

    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "obsidian-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['obsidian-app']"
    end

    # ohos_packing_tool needs SDK libraries outside brew's sanitized search path.
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
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
                    "obsidian-desktop-unsigned.hap"

    # ACL variant: sandbox/file access, pasteboard and the two kernel JIT ACLs;
    # install swaps it in and points signing at the same permissions.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"obsidian-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION
       ohos.permission.READ_PASTEBOARD].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    # The tap checkout is a read-only host mount in CI; install would move files.
    pkgshare.mkpath
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    cp res/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    chmod 0755, pkgshare/"hap-app-install-lib.sh"
    cp res/"scripts/obsidian-desktop.sh", libexec/"obsidian-desktop.sh"
    chmod 0755, libexec/"obsidian-desktop.sh"
    cp res/"scripts/obsidian-cli.cjs", libexec/"obsidian-cli.cjs"
    chmod 0755, libexec/"obsidian-cli.cjs"
    (bin/"obsidian-app").write_env_script libexec/"obsidian-desktop.sh",
      OBSIDIAN_DESKTOP_UNSIGNED_HAP:   libexec/"obsidian-desktop-unsigned.hap",
      OBSIDIAN_DESKTOP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      OBSIDIAN_DESKTOP_MODULE_ACL:     pkgshare/"module-acl.json",
      OBSIDIAN_DESKTOP_CLI:            libexec/"obsidian-cli.cjs",
      OBSIDIAN_DESKTOP_NODE:           formula_opt_bin("node")/"node",
      OBSIDIAN_DESKTOP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      OBSIDIAN_ASAR_URL:               stable.url.to_s,
      OBSIDIAN_ASAR_SHA256:            stable.checksum.hexdigest
    bin.install_symlink bin/"obsidian-app" => "obsidian-desktop"
  end

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "obsidian-app", "com.social4hyq.obsidiandesktop"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  def caveats
    <<~EOS
      `brew install` and `brew upgrade` try to install the HAP when a device is
      connected and Huawei Developer login is ready. If queued, check
      `hap-app status`, then run `hap-app install-pending`.
      Manual install: `obsidian-app install`. See docs/hap-app-formulae.md.

      It downloads Obsidian #{version} from the official release, verifies the
      sha256, injects it into the HAP and signs with a local debug profile;
      `--asar PATH` uses a local copy (offline). Vaults default to
      `~/Obsidian/Obsidian Vault`; paste and WebAssembly work. `--no-acl` gives the
      strong-sandbox variant (vaults in the app sandbox, no paste/JIT).

      CLI: enable Settings -> General -> Command line interface, then
      `obsidian-app cli <command>` (try `cli help`). Desktop self-update is disabled;
      upgrade with `brew upgrade`.

      `obsidian-app uninstall` removes the app but keeps its data; only
      `obsidian-app uninstall --purge` deletes the app data.
    EOS
  end

  test do
    home = testpath/"home"
    home.mkpath
    ENV["HOME"] = home
    help = shell_output("#{bin}/obsidian-app --help")
    assert_match "Usage: obsidian-app", help
    assert_match "cli ...", help
    system formula_opt_bin("node")/"node", "--check", libexec/"obsidian-cli.cjs"

    hap = libexec/"obsidian-desktop-unsigned.hap"
    listing = shell_output("unzip -l #{hap}")
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "resources/resfile/resources/app/bootstrap.cjs", listing
    assert_match "resources/resfile/resources/app/node_modules/@electron/remote/main/index.js", listing
    refute_match "obsidian.asar", listing
    assert_match "com.social4hyq.obsidiandesktop", shell_output("unzip -p #{hap} module.json")
    system "unzip", "-tq", hap

    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_permissions = acl.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO
                    ohos.permission.INTERNET ohos.permission.READ_PASTEBOARD
                    ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_permissions.sort

    fake_bin = testpath/"bin"
    fake_bin.mkpath
    injected = testpath/"injected.hap"
    installer_args = testpath/"installer-args"
    fake_installer = fake_bin/"app-installer"
    fake_installer.write <<~SH
      #!/bin/sh
      printf '%s\n' "$@" > #{installer_args}
      [ "$1" != uninstall ] || exit 0
      out=""
      while [ $# -gt 0 ]; do
        case "$1" in
          --hap) cp "$2" #{injected}; shift 2 ;;
          --signed-hap) out="$2"; shift 2 ;;
          *) shift ;;
        esac
      done
      printf 'signed' > "$out"
    SH
    chmod 0755, fake_installer

    fake_hdc = fake_bin/"hdc"
    fake_hdc.write <<~SH
      #!/bin/sh
      case "$*" in
        *"list targets"*) printf '127.0.0.1:34561\n' ;;
        *) exit 0 ;;
      esac
    SH
    chmod 0755, fake_hdc
    ENV["OBSIDIAN_DESKTOP_HDC"] = fake_hdc.to_s
    ENV["OBSIDIAN_DESKTOP_INSTALLER"] = fake_installer.to_s

    (fake_bin/"devecocli").write "#!/bin/sh\nexit 99\n"
    chmod 0755, fake_bin/"devecocli"

    asar = testpath/"obsidian.asar"
    asar.binwrite([4, 16, 12].pack("V3") + '{"files":{}}')
    ENV.prepend_path "PATH", fake_bin

    # progress messages go to stderr, keep them in the captured output
    assert_match "installed",
                 shell_output("#{bin}/obsidian-app install --asar #{asar} 2>&1")
    assert_match "resources/resfile/resources/app/obsidian.asar", shell_output("unzip -l #{injected}")
    injected_module = JSON.parse(shell_output("unzip -p #{injected} module.json"))
    injected_permissions = injected_module.fetch("module").fetch("requestPermissions").map { |p| p.fetch("name") }
    assert_equal acl_permissions.sort, injected_permissions.sort
    refute_path_exists home/".hap-installer"
    installer = installer_args.read.lines(chomp: true)
    assert_includes installer, "--bundle-id"
    assert_equal fake_hdc.to_s, installer[installer.index("--hdc") + 1]
    assert_match "installed", shell_output("#{bin}/obsidian-app install --asar #{asar} --no-acl 2>&1")
    strong = JSON.parse(shell_output("unzip -p #{injected} module.json"))
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET],
                 strong.fetch("module").fetch("requestPermissions").map { |entry| entry.fetch("name") }.sort
    system "unzip", "-tq", injected

    curl_log = testpath/"curl-args"
    fake_curl = fake_bin/"curl"
    fake_curl.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$@" > #{curl_log}
      while [ "$#" -gt 0 ]; do
        if [ "$1" = "-o" ]; then
          printf 'not an asar' > "$2"
          exit 0
        fi
        shift
      done
      exit 2
    SH
    chmod 0755, fake_curl
    download_env = {
      "OBSIDIAN_DESKTOP_UNSIGNED_HAP" => hap.to_s,
      "OBSIDIAN_ASAR_URL"             => stable.url.to_s,
      "OBSIDIAN_ASAR_SHA256"          => stable.checksum.hexdigest,
      "OBSIDIAN_ASAR_CACHE"           => (testpath/"download-cache").to_s,
    }
    %w[0 1].each do |tls_insecure|
      rm_r testpath/"download-cache" if (testpath/"download-cache").exist?
      curl_log.unlink if curl_log.exist?
      output = with_env(download_env.merge("HAP_INSTALLER_TLS_INSECURE" => tls_insecure)) do
        shell_output("bash #{pkgshare}/install-desktop.sh 2>&1", 1)
      end
      assert_match "sha256 mismatch", output
      curl_args = curl_log.read.lines(chomp: true)
      if tls_insecure == "1"
        assert_includes curl_args, "--insecure"
        assert_match "TLS certificate verification is disabled", output
      else
        refute_includes curl_args, "--insecure"
      end
    end

    # The CLI matrix: start/stop address the device; uninstall goes through
    # app-installer and keeps the app's data unless --purge is given.
    hdc_log = testpath/"cli-hdc-log"
    fake_hdc.delete if fake_hdc.exist?
    fake_hdc.write <<~SH
      #!/bin/sh
      printf '%s\\n' "$*" >> #{hdc_log}
      case "$*" in
        *"list targets"*) printf '127.0.0.1:34561\\n' ;;
        *"ps -ef | grep -q"*) exit 0 ;;
        *) exit 0 ;;
      esac
    SH
    chmod 0755, fake_hdc
    shell_output("#{bin}/obsidian-app start --device tablet-1")
    assert_match "-t tablet-1 shell aa start", (testpath/"cli-hdc-log").read
    shell_output("#{bin}/obsidian-app stop")
    assert_match "shell aa force-stop com.social4hyq.obsidiandesktop", (testpath/"cli-hdc-log").read
    assert_equal "running\n", shell_output("#{bin}/obsidian-app status")
    shell_output("#{bin}/obsidian-app uninstall --purge --device tablet-1")
    assert_equal %w[uninstall --bundle-id com.social4hyq.obsidiandesktop --device tablet-1 --purge],
                 installer_args.read.lines(chomp: true)
    shell_output("#{bin}/obsidian-app uninstall")
    assert_equal %w[uninstall --bundle-id com.social4hyq.obsidiandesktop], installer_args.read.lines(chomp: true)
    with_env("HDC_TARGET" => "env-device") do
      shell_output("#{bin}/obsidian-app uninstall")
    end
    assert_equal %w[uninstall --bundle-id com.social4hyq.obsidiandesktop --device env-device],
                 installer_args.read.lines(chomp: true)
    assert_match "uninstall", shell_output("#{bin}/obsidian-app --help")
  end
end
