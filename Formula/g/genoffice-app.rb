class GenofficeApp < Formula
  desc "GenOffice AI office suite (docs, sheets, slides, PDF, Markdown, HTML) as a HAP"
  homepage "https://github.com/genspark-ai/genoffice"
  # Version follows the upstream GenOffice tag: this packages that release's
  # shell on the CPF-Electron runtime, and the OHOS packaging sources live in
  # Resources/genoffice-app and Patches/genoffice-app.
  url "https://github.com/genspark-ai/genoffice/archive/refs/tags/v0.13.18.tar.gz"
  sha256 "156528d8fa1e6878d6c61d3576d6d6b093eda4abbef223e7fbc4bd4855c9cb08"
  # Apache-2.0 upstream with tap-authored packaging scripts, on the CPF-Electron
  # runtime (Chromium/Electron, mixed MIT/BSD/LGPL).
  license :cannot_represent
  revision 8

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/genoffice-app-v0.13.18-r8"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cbf9f431714f9e9bfd18d7ce3b208bdd324f3a40492710009f4458e15857c2c9"
  end

  depends_on "genoffice" => :build
  depends_on "app-installer"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"
  depends_on "zip"

  # Tap-authored packaging scripts live in the tap so they are reviewable in
  # the PR. Every path is listed literally: the weekly remove-unused-patches
  # job keeps a Resources/ directory only while a formula names it.
  RESOURCE_FILES = %w[
    Resources/_shared/hap-app/install-lib.sh
    Resources/genoffice-app/scripts/genoffice-app.sh
    Resources/genoffice-app/scripts/install-desktop.sh
  ].freeze

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  patch_root = Pathname(__dir__).parent.parent
  Dir[(patch_root/"Patches/genoffice-app/ohos/*.patch").to_s].each do |path|
    patch do
      file Pathname(path).relative_path_from(patch_root).to_s
    end
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/genoffice-app"
    RESOURCE_FILES.each do |file|
      odie "missing tap resource: #{file}" unless (tap_root/file).exist?
    end

    # The xlsx sidecar comes from the genoffice formula (same upstream release,
    # see below), so the two must not drift apart.
    genoffice_version = Formula["genoffice"].version.to_s
    if genoffice_version != version.to_s
      odie "genoffice #{genoffice_version} does not match genoffice-app #{version}"
    end

    # Build the way `npm run build:all` does, with two differences: the root
    # postinstall (which would download an Electron binary) is skipped, and the
    # sheets build script is replaced by a plain electron-vite build, because
    # the xlsx sidecar is not built here. electron-vite only reads the major
    # version of the installed electron package, and the major versions 40 and
    # 43 take the same fallback target in electron-vite 5.0.0, so the output is
    # the same for either.
    system "npm", "ci", "--ignore-scripts"
    # without this the bundled CLI reports the CLI package version (0.10.0)
    ENV["GENOFFICE_APP_VERSION"] = version.to_s
    %w[docs slides pdf markdown html cli].each do |name|
      system "npm", "run", "build", "-w", "@genoffice/#{name}"
    end
    cd "apps/sheets" do
      system buildpath/"node_modules/.bin/electron-vite", "build"
    end
    system "npm", "run", "build", "-w", "@genoffice/shell"

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    # The layout of the packaged upstream app (apps/shell/electron-builder.cjs):
    # the shell itself in app/, everything it reads through process.resourcesPath
    # next to it. Measured under electron-ohos: process.resourcesPath is the
    # HAP's resfile/resources, and app.getAppPath() is its app/ directory.
    resources = shell/"web_engine/src/main/resources/resfile/resources"
    app = resources/"app"
    rm_r app if app.exist?
    app.mkpath
    cp_r buildpath/"apps/shell/out", app/"out"
    package = JSON.parse((buildpath/"apps/shell/package.json").read)
    package = package.slice("name", "productName", "version", "description", "main", "license", "homepage", "author")
    package["version"] = version.to_s
    (app/"package.json").write JSON.generate(package)

    (resources/"modules").mkpath
    %w[docs sheets slides pdf markdown html].each do |name|
      cp_r buildpath/"apps"/name/"out", resources/"modules"/name
    end

    # PDF text editing and .hwp import engines, resolved under resources/wasm
    (resources/"wasm").mkpath
    cp buildpath/"node_modules/@embedpdf/pdfium/dist/pdfium.wasm", resources/"wasm/pdfium.wasm"
    cp buildpath/"apps/pdf/node_modules/harfbuzzjs/hb-subset.wasm", resources/"wasm/hb-subset.wasm"
    cp buildpath/"node_modules/@rhwp/core/rhwp_bg.wasm", resources/"wasm/rhwp_bg.wasm"

    # The genoffice command line the shell runs on its own Node runtime, with
    # the layout packages/cli/src/resources.ts expects.
    cli = resources/"cli"
    cli.mkpath
    cp buildpath/"packages/cli/dist/genoffice.cjs", cli/"genoffice.cjs"
    cp buildpath/"packages/cli/bin/genoffice", cli/"genoffice"
    cp buildpath/"packages/cli/package.json", cli/"package.json"
    cp_r buildpath/"packages/cli/dist/node_modules", cli/"node_modules"
    (cli/"skills/genoffice").mkpath
    cp buildpath/"skills/genoffice/SKILL.md", cli/"skills/genoffice/SKILL.md"
    cp_r buildpath/"skills/recommended", cli/"skills/recommended"

    # The Genspark login CLI (cloud projects). The symlinks npm leaves inside
    # the packages (.bin links) are dropped so no link ends up inside the HAP.
    gsk = resources/"gsk/node_modules"
    (gsk/"@genspark").mkpath
    cp_r buildpath/"node_modules/@genspark/cli", gsk/"@genspark/cli"
    cp_r buildpath/"node_modules/@genspark/cli/node_modules/commander", gsk/"commander"
    cp_r buildpath/"node_modules/ws", gsk/"ws"
    gsk.find { |path| path.unlink if path.symlink? }

    # The xlsx sidecar. An executable inside the HAP takes the .bin suffix: a
    # bare name or .so goes through the packer's native library pipeline and
    # breaks the pre-signed .codesign (the shell is patched to look for it).
    # It is copied from the genoffice keg, not built here: the pipeline signs
    # the ELF files of a keg, but not one inside the HAP (a zip), and an
    # unsigned executable fails to spawn on a device with EACCES. The copy keeps
    # the signature of the keg's file.
    (resources/"native").mkpath
    cp formula_opt_prefix("genoffice")/"libexec/native/xlsx-sidecar", resources/"native/xlsx-sidecar.bin"
    chmod 0755, resources/"native/xlsx-sidecar.bin"

    %w[LICENSE LICENSE-UNICODE.txt NOTICE].each do |name|
      cp buildpath/name, resources/name
    end

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

    # Restricted permissions (pasteboard, user files, ...) cannot be granted
    # with local auto-signing; this trim installs under it and the ACL variant
    # below adds the rest. FILE_ACCESS_PERSIST is a normal, system-granted
    # permission: without it electron-ohos' dialog adapter cannot persist the
    # access to a file picked in the save dialog ("DialogAdapter
    # FileAccessPersist failed, ret=13900011" in hilog) and the path stays
    # unusable for the app.
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\r?\n    \],/m,
              <<~JSON5.chomp
                "requestPermissions": [
                      { "name": "ohos.permission.INTERNET" },
                      { "name": "ohos.permission.GET_NETWORK_INFO" },
                      { "name": "ohos.permission.FILE_ACCESS_PERSIST" }
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
    # ACL-gated permissions (host user files, pasteboard) and the two kernel
    # ACLs that let the renderer use WebAssembly (pdfium, rhwp), for devices
    # whose signing profile carries them.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"genoffice-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.READ_PASTEBOARD
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
      The desktop HAP is unsigned in the bottle. Connect and unlock the device,
      then run `genoffice-app install`. app-installer handles Huawei Developer
      login, local debug profile generation, signing, installation, and launch;
      `genoffice-app start` opens it again.

      The app runs entirely inside its own sandbox. The weak-sandbox permissions
      CUSTOM_SANDBOX and READ_WRITE_USER_FILE (host user files) and
      READ_PASTEBOARD (paste) are granted through a debug profile generated on
      the spot, and the two kernel ACLs enable WebAssembly for the renderer.
      The `genoffice` command line of the `genoffice` formula is a separate
      tool: it cannot reach the app's sandbox, so `genoffice open` does not
      control this app.
    EOS
  end

  test do
    assert_match "Usage: genoffice-app", shell_output("#{bin}/genoffice-app --help")

    hap = libexec/"genoffice-desktop-unsigned.hap"
    listing = shell_output("unzip -l #{hap}")
    %w[
      resources/resfile/resources/app/package.json
      resources/resfile/resources/app/out/main/index.js
      resources/resfile/resources/modules/sheets/renderer/index.html
      resources/resfile/resources/modules/sheets/preload/index.js
      resources/resfile/resources/wasm/pdfium.wasm
      resources/resfile/resources/cli/genoffice.cjs
      resources/resfile/resources/native/xlsx-sidecar.bin
    ].each { |entry| assert_match entry, listing }

    package = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/package.json"))
    assert_equal "out/main/index.js", package["main"]
    assert_equal version.to_s, package["version"]

    # an unsigned sidecar cannot be spawned on a device (EACCES); the signed
    # file of the genoffice keg carries a code signature section, a fresh build
    # does not
    sidecar_signature = shell_output("unzip -p #{hap} resources/resfile/resources/native/xlsx-sidecar.bin | " \
                                     "grep -a -c -i codesign")
    assert_operator sidecar_signature.to_i, :>, 0

    module_json = JSON.parse(shell_output("unzip -p #{hap} module.json"))
    assert_equal %w[ohos.permission.FILE_ACCESS_PERSIST ohos.permission.GET_NETWORK_INFO ohos.permission.INTERNET],
                 module_json.dig("module", "requestPermissions").map { |permission| permission["name"] }.sort

    acl_module = JSON.parse((pkgshare/"module-acl.json").read)
    acl_permissions = acl_module.dig("module", "requestPermissions").map { |permission| permission["name"] }
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE ohos.permission.READ_PASTEBOARD
       ohos.permission.FILE_ACCESS_PERSIST ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY].each do |permission|
      assert_includes acl_permissions, permission
    end
  end
end
