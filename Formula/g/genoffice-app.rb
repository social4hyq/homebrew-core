class GenofficeApp < Formula
  desc "Runtime probe for the GenOffice desktop shell on electron-ohos (experimental)"
  homepage "https://github.com/genspark-ai/genoffice"
  # Version follows the upstream GenOffice tag. This experiment builds no
  # upstream code; it only borrows the app icon from the release tarball.
  url "https://github.com/genspark-ai/genoffice/archive/refs/tags/v0.13.18.tar.gz"
  sha256 "156528d8fa1e6878d6c61d3576d6d6b093eda4abbef223e7fbc4bd4855c9cb08"
  # Tap-authored probe sources packaging the CPF-Electron runtime
  # (Chromium/Electron, mixed MIT/BSD/LGPL) and the Apache-2.0 upstream icon.
  license :cannot_represent

  depends_on "app-installer"
  depends_on "genoffice"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"
  depends_on "zip"

  # Probe sources live in the tap so they are reviewable in the PR. Every path
  # is listed literally: the weekly remove-unused-patches job keeps a
  # Resources/ directory only while a formula names it.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/install-lib.sh
    Resources/genoffice-app/app/index.html
    Resources/genoffice-app/app/main.cjs
    Resources/genoffice-app/app/package.json
    Resources/genoffice-app/scripts/genoffice-app.sh
    Resources/genoffice-app/scripts/install-desktop.sh
  ].freeze

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/genoffice-app"
    RESOURCE_FILES.each do |file|
      odie "missing tap resource: #{file}" unless (tap_root/file).exist?
    end

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    # Layout under test: the app directory next to a native/ directory and a
    # marker file, the way the GenOffice shell expects process.resourcesPath to
    # look. The probe reports which directory electron-ohos really calls
    # resourcesPath, and whether the embedded executable can be spawned. The
    # executable is the sidecar of the genoffice formula; it takes the .bin
    # suffix because a file without an extension (or a .so) goes through the
    # hvigor native library pipeline and breaks the pre-signed .codesign.
    resources = shell/"web_engine/src/main/resources/resfile/resources"
    app = resources/"app"
    rm_r app if app.exist?
    app.mkpath
    %w[main.cjs index.html package.json].each do |name|
      cp res/"app"/name, app/name
    end
    (resources/"probe-marker.txt").write "resources\n"
    (app/"probe-marker.txt").write "app\n"
    (resources/"native").mkpath
    cp formula_opt_prefix("genoffice")/"libexec/native/xlsx-sidecar", resources/"native/xlsx-sidecar.bin"
    chmod 0755, resources/"native/xlsx-sidecar.bin"

    inreplace shell/"AppScope/app.json5", '"bundleName": "com.huawei.ohos_electron"',
                                          '"bundleName": "com.social4hyq.genoffice"'
    inreplace shell/"AppScope/app.json5", '"vendor": "example"', '"vendor": "social4hyq"'
    %w[app_icon.png startIcon.png].each do |name|
      cp buildpath/"apps/shell/build/icons/512x512.png", shell/"AppScope/resources/base/media"/name
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
        when "app_name", "EntryAbility_label" then entry["value"] = "GenOffice"
        end
      end
      rm file
      file.write JSON.pretty_generate(strings) + "\n"
    end

    # CI's electron-ohos-ci CLT carries an NDK-less SDK subset (no llvm-strip);
    # mirror the packaging deltas that keep hvigor away from the strip task and
    # from signing material the container does not have.
    inreplace shell/"build-profile.json5", /^[ \t]*"signingConfig": "default",\r?\n/, ""
    inreplace shell/"electron/src/main/module.json5", '"mainElement": "EntryAbility",',
              '"mainElement": "EntryAbility", "extractNativeLibs": true,'

    # The probe only needs loopback HTTP; this trim installs under local
    # auto-signing.
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\r?\n    \],/m,
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
      odie "genoffice-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['genoffice-app']"
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
                    "genoffice-desktop-unsigned.hap"

    # The default HAP requests only what local automatic signing can grant.
    # `genoffice-app install` swaps in this variant, which also requests the
    # two ACL-gated permissions (weak sandbox) and the two kernel ACLs that let
    # the renderer use WebAssembly, for devices whose signing profile carries
    # them. The probe's report shows what the default variant can already do.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"genoffice-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # cp, not install: Pathname#install moves the source, and the tap checkout
    # is a read-only host mount inside the CI container.
    pkgshare.mkpath
    cp res/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
    # install-desktop.sh sources the install flow shared by the HAP apps from
    # the same directory.
    cp tap_root/"Resources/_shared/hap-app/install-lib.sh", pkgshare/"hap-app-install-lib.sh"
    chmod 0755, pkgshare/"hap-app-install-lib.sh"
    cp res/"scripts/genoffice-app.sh", libexec/"genoffice-desktop.sh"
    chmod 0755, libexec/"genoffice-desktop.sh"
    (bin/"genoffice-app").write_env_script libexec/"genoffice-desktop.sh",
      GENOFFICE_DESKTOP_UNSIGNED_HAP:   libexec/"genoffice-desktop-unsigned.hap",
      GENOFFICE_DESKTOP_INSTALL_SCRIPT: pkgshare/"install-desktop.sh",
      GENOFFICE_DESKTOP_MODULE_ACL:     pkgshare/"module-acl.json",
      GENOFFICE_DESKTOP_HDC_DEFAULT:    formula_opt_prefix("ohos-sdk-toolchains")/"hdc",
      PATH:                             "#{formula_opt_bin("node")}:$PATH"
  end

  def caveats
    <<~EOS
      This is an experiment, not the GenOffice desktop app: the HAP only reports
      what electron-ohos exposes to an app (app.isPackaged, process.resourcesPath,
      whether an embedded executable can be spawned, the file systems under the
      app state) so the real shell can be laid out for it.

      Connect and unlock the device, then:
        genoffice-app probe     # in one terminal: listens for the report
        genoffice-app install   # signs and installs the unsigned HAP
        genoffice-app start

      The report is printed by `probe` and kept under ~/.config/genoffice-app.
    EOS
  end

  test do
    assert_match "Usage: genoffice-app", shell_output("#{bin}/genoffice-app --help")

    hap = libexec/"genoffice-desktop-unsigned.hap"
    listing = shell_output("unzip -l #{hap}")
    %w[
      resources/resfile/resources/app/main.cjs
      resources/resfile/resources/native/xlsx-sidecar.bin
      resources/resfile/resources/probe-marker.txt
    ].each { |entry| assert_match entry, listing }

    module_json = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal %w[ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET],
                 module_json.dig("module", "requestPermissions").map { |permission| permission["name"] }.sort

    acl_module = JSON.parse((pkgshare/"module-acl.json").read)
    acl_permissions = acl_module.dig("module", "requestPermissions").map { |permission| permission["name"] }
    assert_includes acl_permissions, "ohos.permission.CUSTOM_SANDBOX"
    assert_includes acl_permissions, "ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY"
  end
end
