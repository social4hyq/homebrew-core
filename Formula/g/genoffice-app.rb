class GenofficeApp < Formula
  desc "GenOffice AI office suite (docs, sheets, slides, PDF, Markdown, HTML) as a HAP"
  homepage "https://github.com/genspark-ai/genoffice"
  url "https://github.com/genspark-ai/genoffice/archive/refs/tags/v0.13.18.tar.gz"
  sha256 "156528d8fa1e6878d6c61d3576d6d6b093eda4abbef223e7fbc4bd4855c9cb08"
  # Apache-2.0 upstream with tap-authored packaging on the CPF-Electron runtime
  # (mixed MIT/BSD/LGPL).
  license :cannot_represent
  revision 13

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/genoffice-app-v0.13.18-r17"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d0492b97a0e3e1c9663425be7fd50eab8a711a9d309e536172eb08ebe2d09f10"
  end

  depends_on "genoffice" => :build
  depends_on "app-installer"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"
  depends_on "zip"

  # The unused-resource audit requires literal tap paths.
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
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    # The xlsx sidecar comes from the `genoffice` formula (same release); keep
    # the two in sync.
    genoffice_version = Formula["genoffice"].version.to_s
    if genoffice_version != version.to_s
      odie "genoffice #{genoffice_version} does not match genoffice-app #{version}"
    end

    # Build like `npm run build:all`, skipping the root postinstall (it would
    # download Electron) and using a plain electron-vite build for the shell;
    # the xlsx sidecar is not built here.
    system "npm", "ci", "--ignore-scripts"
    # Keeps the bundled CLI from reporting its package version (0.10.0).
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

    # Packaged layout: the shell in app/, resources next to it
    # (process.resourcesPath is the HAP's resfile/resources; app is app/).
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

    # The CLI the shell runs on its own Node runtime (layout from
    # packages/cli/src/resources.ts).
    cli = resources/"cli"
    cli.mkpath
    cp buildpath/"packages/cli/dist/genoffice.cjs", cli/"genoffice.cjs"
    cp buildpath/"packages/cli/bin/genoffice", cli/"genoffice"
    cp buildpath/"packages/cli/package.json", cli/"package.json"
    cp_r buildpath/"packages/cli/dist/node_modules", cli/"node_modules"
    (cli/"skills/genoffice").mkpath
    cp buildpath/"skills/genoffice/SKILL.md", cli/"skills/genoffice/SKILL.md"
    cp_r buildpath/"skills/recommended", cli/"skills/recommended"

    # The Genspark login CLI; drop npm's .bin symlinks so no link lands in the
    # HAP.
    gsk = resources/"gsk/node_modules"
    (gsk/"@genspark").mkpath
    cp_r buildpath/"node_modules/@genspark/cli", gsk/"@genspark/cli"
    cp_r buildpath/"node_modules/@genspark/cli/node_modules/commander", gsk/"commander"
    cp_r buildpath/"node_modules/ws", gsk/"ws"
    gsk.find { |path| path.unlink if path.symlink? }

    # xlsx sidecar: it needs the .bin suffix (bare names and .so go through the
    # native-library pipeline and break .codesign). Copy it from the genoffice
    # keg: the pipeline signs keg ELF files but not files inside the HAP, and an
    # unsigned executable fails to spawn (EACCES); the copy keeps the signature.
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
    # Locale overrides would otherwise keep the Electron launcher label.
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

    # The CI SDK lacks llvm-strip and local signing material.
    inreplace shell/"build-profile.json5", /^[ \t]*"signingConfig": "default",\r?\n/, ""
    inreplace shell/"electron/src/main/module.json5", '"mainElement": "EntryAbility",',
              '"mainElement": "EntryAbility", "extractNativeLibs": true,'

    # Trim ACL-gated permissions (pasteboard, user files, kernel ACLs) that
    # local auto-signing cannot grant; the ACL variant below adds them.
    # FILE_ACCESS_PERSIST is system-granted and still required by the
    # save-dialog adapter.
    inreplace shell/"web_engine/src/main/module.json5", /"requestPermissions": \[.*?\r?\n    \],/m,
              <<~JSON5.chomp
                "requestPermissions": [
                      { "name": "ohos.permission.INTERNET" },
                      { "name": "ohos.permission.GET_NETWORK_INFO" },
                      { "name": "ohos.permission.FILE_ACCESS_PERSIST" }
                    ],
              JSON5

    # The proprietary CLT is supplied by the CI image, not distributed by the tap.
    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "genoffice-app builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['genoffice-app']"
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
                    "genoffice-desktop-unsigned.hap"

    # The ACL variant also requests the ACL-gated permissions (user files,
    # pasteboard) and the two kernel ACLs (WebAssembly for pdfium/rhwp).
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

    # Pathname#install would move files out of the read-only CI tap.
    pkgshare.mkpath
    cp res/"scripts/install-desktop.sh", pkgshare/"install-desktop.sh"
    chmod 0755, pkgshare/"install-desktop.sh"
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

  post_install_steps do
    run "{{HOMEBREW_PREFIX}}/bin/hap-app",
        args: ["auto-install", "genoffice-app", "com.social4hyq.genoffice"],
        must_succeed: false, print_stdout: true, network_access: true
  end

  def caveats
    <<~EOS
      `brew install` and `brew upgrade` try to install the HAP when a device is
      connected and Huawei Developer login is ready. If queued, check
      `hap-app status`, then run `hap-app install-pending`.
      Manual install: `genoffice-app install`. See docs/hap-app-formulae.md.

      The app runs entirely in its own sandbox: CUSTOM_SANDBOX, READ_WRITE_USER_FILE
      and READ_PASTEBOARD come from the local debug profile, and the kernel ACLs keep
      WebAssembly working. The `genoffice` CLI is a separate tool that cannot reach
      the app.
    EOS
  end

  test do
    assert_match "Usage: genoffice-app", shell_output("#{bin}/genoffice-app --help")

    hap = libexec/"genoffice-desktop-unsigned.hap"
    listing = shell_output("unzip -l #{hap}")
    %w[
      resources/resfile/resources/modules/sheets/renderer/index.html
      resources/resfile/resources/modules/sheets/preload/index.js
      resources/resfile/resources/wasm/pdfium.wasm
      resources/resfile/resources/cli/genoffice.cjs
    ].each { |entry| assert_match entry, listing }

    package = JSON.parse(shell_output("unzip -p #{hap} resources/resfile/resources/app/package.json"))
    assert_includes listing, "resources/resfile/resources/app/#{package.fetch("main")}"
    assert_equal version.to_s, package["version"]

    # An unsigned sidecar cannot be spawned (EACCES); the keg copy carries the
    # code signature.
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
