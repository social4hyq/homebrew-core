class ObsidianDesktop < Formula
  desc "Notes desktop for HarmonyOS PC running the official Obsidian package"
  homepage "https://obsidian.md"
  url "https://github.com/social4hyq/homebrew-core/releases/download/obsidian-desktop-v0.1.0/obsidian-desktop-0.1.0.tar.gz"
  sha256 "3a9b494710eac84b00f6fbef28bf7ec40b5899c780e5ac5c0ca4739133a4b114"
  # Tap-authored host/scripts (MIT) packaging the openharmony-sig Electron
  # prebuilt. Obsidian itself is proprietary and is never redistributed here:
  # the official Linux arm64 package is fetched on the user's machine at
  # install time; see obsidian.md terms and multica.rb.
  license :cannot_represent

  livecheck do
    skip "Tap-hosted payload, versioned with the formula"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/obsidian-desktop-v0.1.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "936501aa5d90c987f2da9389b3e71708f2aaaf198248bde6db5b74fe586b7c3d"
  end

  depends_on "node" => :build
  depends_on "curl"
  depends_on "hap-installer"
  depends_on "ohos-sdk-toolchains"
  depends_on "zip"

  # Version of the vendor app package this formula's host was verified against.
  # Bump together with the asar URL/digest; the host contract (app:// scheme,
  # @electron/remote, documents redirect) has been stable across 1.12 through
  # 1.15.
  OBSIDIAN_VERSION = "1.15.1".freeze
  OBSIDIAN_ASAR_URL = "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.15.1/obsidian-1.15.1.asar.gz".freeze
  OBSIDIAN_ASAR_SHA256 = "3f6808c14204063349d5a7a59b9f2f637958063fa85eeebe767e13e06d314c0f".freeze

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

    # Host payload only: bootstrap + @electron/remote. The vendor app package
    # (obsidian.asar) is injected by `obsidian-desktop install`, so this HAP
    # stays free of closed-source bytes.
    app = shell/"web_engine/src/main/resources/resfile/resources/app"
    rm_r app if app.exist?
    app.mkpath
    cp buildpath/"app/bootstrap.cjs", app/"bootstrap.cjs"
    cp buildpath/"app/package.json", app/"package.json"
    cp_r buildpath/"app/node_modules", app/"node_modules"

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
      cp buildpath/"assets/icon.png", shell/"AppScope/resources/base/media"/name
    end
    cp buildpath/"assets/icon32.png", shell/"AppScope/resources/base/media/product_logo_32.png"

    # CI's electron-ohos-ci CLT carries an NDK-less SDK subset (no llvm-strip);
    # mirror the multica/opencode packaging deltas that keep hvigor away from
    # the strip task and from signing material the container does not have.
    inreplace shell/"build-profile.json5", "        \"signingConfig\": \"default\",\n", ""
    inreplace shell/"electron/src/main/module.json5", "    \"mainElement\": \"EntryAbility\",\n",
              "    \"mainElement\": \"EntryAbility\",\n    \"extractNativeLibs\": true,\n"

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
      odie "obsidian-desktop builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['obsidian-desktop']"
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
    # two kernel JIT ACLs. `obsidian-desktop install` swaps it into the HAP copy
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
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    pkgshare.install buildpath/"scripts/install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    libexec.install buildpath/"scripts/obsidian-desktop.sh"
    chmod 0755, libexec/"obsidian-desktop.sh"
    (bin/"obsidian-desktop").write_env_script libexec/"obsidian-desktop.sh",
      OBSIDIAN_DESKTOP_UNSIGNED_HAP:   libexec/"obsidian-desktop-unsigned.hap",
      OBSIDIAN_DESKTOP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      OBSIDIAN_DESKTOP_MODULE_ACL:     pkgshare/"module-acl.json",
      OBSIDIAN_DESKTOP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      OBSIDIAN_ASAR_URL:               OBSIDIAN_ASAR_URL,
      OBSIDIAN_ASAR_SHA256:            OBSIDIAN_ASAR_SHA256
  end

  def caveats
    <<~EOS
      The desktop HAP is unsigned in the bottle and contains no Obsidian code.
      Connect and unlock the device, then run:

        obsidian-desktop install

      It downloads Obsidian #{OBSIDIAN_VERSION} from Obsidian's official release,
      checks the pinned sha256, injects the app package into the HAP, signs with
      a locally generated debug profile, installs and starts it. Use
      `obsidian-desktop install --asar PATH` to install from a local copy
      instead (offline devices).

      The HAP requests the weak-sandbox ACLs (CUSTOM_SANDBOX,
      READ_WRITE_USER_FILE, READ_PASTEBOARD) and the two kernel JIT ACLs, and
      `install` points the signing project at the same list. hap-installer
      generates the matching local debug profile, so vaults live in your home
      directory (default ~/Obsidian/Obsidian Vault), image paste works, and the
      renderer keeps WebAssembly. The first install asks for a Huawei Developer
      login to create the profile. ACL profiles need a hap-installer whose
      toolchain ships the SDK permission definitions (tap hap-installer r3+);
      an older one silently generates a profile without ACLs and the device
      rejects the install with 9568289. `--no-acl` installs the strong-sandbox
      variant instead (vaults in the app sandbox, no paste, no JIT).

      Desktop self-update is disabled; upgrading is `brew upgrade` plus
      `obsidian-desktop install`. Bumping Obsidian means bumping
      OBSIDIAN_VERSION, OBSIDIAN_ASAR_URL and OBSIDIAN_ASAR_SHA256.
    EOS
  end

  test do
    home = testpath/"home"
    home.mkpath
    ENV["HOME"] = home
    assert_match "Usage: obsidian-desktop", shell_output("#{bin}/obsidian-desktop --help")

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
    fake_installer = fake_bin/"hap-installer"
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

    fake_devecocli = fake_bin/"devecocli"
    fake_devecocli.write <<~SH
      #!/bin/sh
      case "$1" in
        create)
          project=""
          while [ $# -gt 0 ]; do
            if [ "$1" = "--project-path" ]; then project="$2"; shift; fi
            shift
          done
          mkdir -p "$project/entry/src/main"
          printf '{\n  "module": {\n    "name": "entry",\n    "type": "entry"\n  }\n}\n' > "$project/entry/src/main/module.json5"
          printf '{"app":{"signingConfigs":[]}}\n' > "$project/build-profile.json5"
          ;;
      esac
    SH
    chmod 0755, fake_devecocli

    asar = testpath/"obsidian.asar"
    asar.binwrite([4, 16, 12].pack("V3") + '{"files":{}}')
    ENV.prepend_path "PATH", fake_bin

    # progress messages go to stderr, keep them in the captured output
    assert_match "installed and started",
                 shell_output("#{bin}/obsidian-desktop install --asar #{asar} 2>&1")
    assert_match "--bundle-id", installer_args.read
    assert_match "resources/resfile/resources/app/obsidian.asar", shell_output("unzip -l #{injected}")
    injected_module = JSON.parse(shell_output("unzip -p #{injected} module.json"))
    injected_permissions = injected_module.fetch("module").fetch("requestPermissions").map { |p| p.fetch("name") }
    assert_equal acl_permissions.sort, injected_permissions.sort
    signing_project = home/".hap-installer/projects/com.social4hyq.obsidiandesktop"
    assert_match "READ_PASTEBOARD", (signing_project/"entry/src/main/module.json5").read
    system "unzip", "-tq", injected
  end
end
