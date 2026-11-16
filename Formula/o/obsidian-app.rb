class ObsidianApp < Formula
  desc "Notes desktop for HarmonyOS PC running the official Obsidian package"
  homepage "https://obsidian.md"
  url "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.15.1/obsidian-1.15.1.asar.gz"
  sha256 "3f6808c14204063349d5a7a59b9f2f637958063fa85eeebe767e13e06d314c0f"
  # The stable url is the vendor app package, so `version`, `brew bump-formula-pr`
  # and autobump all follow Obsidian itself. The tap-authored host payload lives
  # under Patches/obsidian-app and stays version-independent. Obsidian is
  # proprietary and is never redistributed here: the asar is fetched from
  # Obsidian's own release at install time (never copied into the bottle); see
  # obsidian.md terms and multica.rb.
  license :cannot_represent
  revision 5

  # Upstream is the vendor app, not the tap-authored host payload: the formula
  # version tracks Obsidian so `brew upgrade` follows new releases, while the
  # payload stays version-independent. desktop-releases.json carries the latest
  # desktop version together with the asar URL and its sha256.
  livecheck do
    url "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json"
    strategy :json do |json|
      json["latestVersion"]
    end
  end

  depends_on "app-installer"
  depends_on "curl"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"
  depends_on "zip"

  # The payload is copied from the tap's read-only checkout during CI. Keep all
  # source files literal here so remove-unused-patches preserves the directory.
  PAYLOAD_FILES = %w[
    Patches/obsidian-app/app/bootstrap.cjs
    Patches/obsidian-app/app/node_modules/@electron/remote/LICENSE
    Patches/obsidian-app/app/node_modules/@electron/remote/README.md
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/common/get-electron-binding.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/common/get-electron-binding.js
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/common/ipc-messages.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/common/ipc-messages.js
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/common/module-names.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/common/module-names.js
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/common/type-utils.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/common/type-utils.js
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/main/index.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/main/index.js
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/main/objects-registry.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/main/objects-registry.js
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/main/server.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/main/server.js
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/callbacks-registry.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/callbacks-registry.js
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/index.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/index.js
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/remote.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/dist/src/renderer/remote.js
    Patches/obsidian-app/app/node_modules/@electron/remote/index.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/main/index.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/main/index.js
    Patches/obsidian-app/app/node_modules/@electron/remote/package.json
    Patches/obsidian-app/app/node_modules/@electron/remote/renderer/index.d.ts
    Patches/obsidian-app/app/node_modules/@electron/remote/renderer/index.js
    Patches/obsidian-app/app/package.json
    Patches/obsidian-app/assets/icon.png
    Patches/obsidian-app/assets/icon32.png
    Patches/obsidian-app/scripts/install-desktop.sh
    Patches/obsidian-app/scripts/obsidian-cli.cjs
    Patches/obsidian-app/scripts/obsidian-desktop.sh
  ].freeze

  # CPF-Electron's OpenHarmony desktop build, downloaded directly from GitCode.
  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    payload = tap_root/"Patches/obsidian-app"
    PAYLOAD_FILES.each do |path|
      odie "missing tap payload: #{path}" unless (tap_root/path).exist?
    end

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    # Host payload only: bootstrap + @electron/remote. The vendor app package
    # (obsidian.asar) is injected by `obsidian-app install`, so this HAP
    # stays free of closed-source bytes.
    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    cp payload/"app/bootstrap.cjs", app/"bootstrap.cjs"
    cp payload/"app/package.json", app/"package.json"
    cp_r payload/"app/node_modules", app/"node_modules"

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.obsidiandesktop"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    # App name and ability labels live in per-locale string resources: patching
    # only the base file leaves the zh_CN/en_US overrides intact and the
    # launcher keeps showing the template's "Electron" label.
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

    # Icons: the template ships the Electron logo and the copied working project
    # still had the OpenCode icon, so brand from the vendor package's own icon
    # (assets/ comes from the official tarball's resources/icon.png).
    %w[app_icon.png startIcon.png].each do |name|
      cp payload/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    cp payload/"assets/icon32.png", shell/"AppScope/resources/base/media/product_logo_32.png"

    # The Electron template ships CRLF in files patched below; normalize them so
    # exact replacements and the deep-link insertion work across release builds.
    [
      shell/"build-profile.json5",
      shell/"electron/src/main/module.json5",
      shell/"electron/src/main/ets/entryability/EntryAbility.ets",
      shell/"web_engine/src/main/module.json5",
    ].each do |file|
      text = file.read
      file.atomic_write(text.gsub("\r\n", "\n")) if text.include?("\r\n")
    end

    # CI's electron-ohos-ci CLT carries an NDK-less SDK subset (no llvm-strip);
    # mirror the multica/opencode packaging deltas that keep hvigor away from
    # the strip task and from signing material the container does not have.
    inreplace shell/"build-profile.json5", "        \"signingConfig\": \"default\",\n", ""
    inreplace shell/"electron/src/main/module.json5", "    \"mainElement\": \"EntryAbility\",\n",
              "    \"mainElement\": \"EntryAbility\",\n    \"extractNativeLibs\": true,\n"

    # Deep links: register obsidian:// and persist a cold-start launch uri.
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

    # Restricted permissions cannot be granted with local auto-signing. The
    # strong-sandbox shell only needs network access; vaults live in the app
    # sandbox (Documents redirect) until an ACL variant exists.
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

    # brew's sanitized build env drops the container's LD_LIBRARY_PATH, but
    # ohos_packing_tool needs the SDK clang runtimes baked into the image.
    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    # A container inheriting RLIMIT_NOFILE near 1e9 drives the musl FD-table
    # sizing into a refused mapping; cap it for the hvigor process tree.
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
                    "obsidian-desktop-unsigned.hap"

    # ACL variant of module.json: sandbox/file access, pasteboard reads and the
    # two kernel JIT ACLs. `obsidian-app install` swaps it into the HAP copy
    # and points the signing project at the same permissions, so hap-installer's
    # locally generated debug profile carries them (no AGC profile needed).
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

    cp payload/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    cp payload/"scripts/obsidian-desktop.sh", libexec/"obsidian-desktop.sh"
    chmod 0755, libexec/"obsidian-desktop.sh"
    cp payload/"scripts/obsidian-cli.cjs", libexec/"obsidian-cli.cjs"
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

  def caveats
    <<~EOS
      The desktop HAP is unsigned in the bottle and contains no Obsidian code.
      Connect and unlock the device, then run:

        obsidian-app install

      It downloads Obsidian #{version} from Obsidian's official release,
      checks the pinned sha256, injects the app package into the HAP, signs with
      a locally generated debug profile, installs and starts it. Use
      `obsidian-app install --asar PATH` to install from a local copy
      instead (offline devices).

      The HAP requests the weak-sandbox ACLs (CUSTOM_SANDBOX,
      READ_WRITE_USER_FILE, READ_PASTEBOARD) and the two kernel JIT ACLs, and
      `install` points the signing project at the same list. app-installer
      generates the matching local debug profile, so vaults live in your home
      directory (default ~/Obsidian/Obsidian Vault), image paste works, and the
      renderer keeps WebAssembly. The first install asks for a Huawei Developer
      login to create the profile. ACL profiles need a app-installer whose
      toolchain ships the SDK permission definitions (tap app-installer r3+);
      an older one silently generates a profile without ACLs and the device
      rejects the install with 9568289. `--no-acl` installs the strong-sandbox
      variant instead (vaults in the app sandbox, no paste, no JIT).

      Command line interface: enable Settings -> General -> Command line
      interface once, then use `obsidian-app cli <command>` (same commands
      as Obsidian's own `obsidian` CLI: try `obsidian-app cli help`). The
      app listens on a UNIX socket inside its sandbox; the host process bridges
      it to loopback TCP with a token stored in
      ~/.cache/obsidian-app/cli.json.

      Desktop self-update is disabled; upgrading is `brew upgrade` plus
      `obsidian-app install`. The formula version follows Obsidian's
      releases, so `brew bump-formula-pr` / autobump handles a new version
      without touching the host payload.
    EOS
  end

  test do
    home = testpath/"home"
    home.mkpath
    ENV["HOME"] = home
    assert_match "Usage: obsidian-app", shell_output("#{bin}/obsidian-app --help")
    assert_match "cli ...", shell_output("#{bin}/obsidian-app --help")
    assert_path_exists libexec/"obsidian-cli.cjs"

    hap = libexec/"obsidian-desktop-unsigned.hap"
    assert_path_exists hap
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

    # `install` injects the vendor package before signing and hands the HAP to
    # the (fake) hap-installer, which is where the ACL profile is generated.
    fake_bin = testpath/"bin"
    fake_bin.mkpath
    injected = testpath/"injected.hap"
    installer_args = testpath/"installer-args"
    fake_installer = fake_bin/"app-installer"
    fake_installer.write <<~SH
      #!/bin/sh
      printf '%s\n' "$@" > #{installer_args}
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

    (fake_bin/"devecocli").write "#!/bin/sh\nexit 99\n"
    chmod 0755, fake_bin/"devecocli"

    asar = testpath/"obsidian.asar"
    asar.binwrite([4, 16, 12].pack("V3") + '{"files":{}}')
    ENV.prepend_path "PATH", fake_bin

    # progress messages go to stderr, keep them in the captured output
    assert_match "installed",
                 shell_output("#{bin}/obsidian-app install --asar #{asar} 2>&1")
    assert_match "--bundle-id", installer_args.read
    assert_match "resources/resfile/resources/app/obsidian.asar", shell_output("unzip -l #{injected}")
    injected_module = JSON.parse(shell_output("unzip -p #{injected} module.json"))
    injected_permissions = injected_module.fetch("module").fetch("requestPermissions").map { |p| p.fetch("name") }
    assert_equal acl_permissions.sort, injected_permissions.sort
    refute_path_exists home/".hap-installer"
    installer = installer_args.read.lines(chomp: true)
    assert_equal fake_hdc.to_s, installer[installer.index("--hdc") + 1]
    assert_match "installed", shell_output("#{bin}/obsidian-app install --asar #{asar} --no-acl 2>&1")
    strong = JSON.parse(shell_output("unzip -p #{injected} module.json"))
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET],
                 strong.fetch("module").fetch("requestPermissions").map { |entry| entry.fetch("name") }.sort
    system "unzip", "-tq", injected
  end
end
