class ObsidianDesktop < Formula
  desc "Notes desktop for HarmonyOS PC running the official Obsidian package"
  homepage "https://obsidian.md"
  url "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.15.1/obsidian-1.15.1.asar.gz"
  sha256 "3f6808c14204063349d5a7a59b9f2f637958063fa85eeebe767e13e06d314c0f"
  # The url is the vendor asar, so version and autobump follow Obsidian; the
  # host payload in Resources/obsidian-desktop is version-independent and the
  # asar is not bundled in the HAP.
  license :cannot_represent
  revision 17

  # desktop-releases.json carries the latest desktop version, asar URL and
  # sha256.
  livecheck do
    url "https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json"
    strategy :json do |json|
      json["latestVersion"]
    end
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/obsidian-desktop-v1.15.1-r6"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6845a7d9fba90be1e659c2e3148f9ef73651690a03471d27c33e9d398b1175fd"
  end

  depends_on "curl"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"
  depends_on "zip"

  # The unused-resource audit requires literal tap paths.
  RESOURCE_FILES = %w[
    Resources/obsidian-desktop/app/bootstrap.cjs
    Resources/obsidian-desktop/app/node_modules/@electron/remote/LICENSE
    Resources/obsidian-desktop/app/node_modules/@electron/remote/README.md
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/common/get-electron-binding.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/common/get-electron-binding.js
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/common/ipc-messages.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/common/ipc-messages.js
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/common/module-names.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/common/module-names.js
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/common/type-utils.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/common/type-utils.js
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/main/index.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/main/index.js
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/main/objects-registry.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/main/objects-registry.js
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/main/server.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/main/server.js
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/renderer/callbacks-registry.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/renderer/callbacks-registry.js
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/renderer/index.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/renderer/index.js
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/renderer/remote.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/dist/src/renderer/remote.js
    Resources/obsidian-desktop/app/node_modules/@electron/remote/index.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/main/index.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/main/index.js
    Resources/obsidian-desktop/app/node_modules/@electron/remote/package.json
    Resources/obsidian-desktop/app/node_modules/@electron/remote/renderer/index.d.ts
    Resources/obsidian-desktop/app/node_modules/@electron/remote/renderer/index.js
    Resources/obsidian-desktop/app/package.json
    Resources/obsidian-desktop/assets/icon.png
    Resources/obsidian-desktop/assets/icon32.png
  ].freeze

  resource "electron-ohos" do
    url "https://gitcode.com/CPF-Electron/Electron/releases/download/v40.0.1/v40.0.1.20261028.2-release.zip"
    sha256 "5268fe3c994ec2ce48a999fd6b5029d9cb0e409b07c0395e2a6072e50cb3e1ac"
  end

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/obsidian-desktop"
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }

    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath
    system "tar", "-xzf", buildpath/"libelectron_144.tar.gz", "-C", buildpath
    shell = buildpath/"libelectron/ohos_hap"

    # Only the host payload is packaged into the HAP; the vendor asar is not
    # bundled.
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
                      { "name": "ohos.permission.GET_NETWORK_INFO" },
                      { "name": "ohos.permission.MICROPHONE", "reason": "$string:microphone", "usedScene": { "abilities": ["EntryAbility"], "when": "inuse" } }
                    ],
              JSON5

    clt = Pathname.new("/opt/electron-ohos-clt")
    unless (clt/"hvigor/bin/hvigorw.js").exist?
      odie "#{name} builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES['#{name}']"
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

    # The ACL variant adds sandbox/file access, pasteboard and the two kernel
    # JIT ACLs; the descriptor exposes it as the default variant.
    hap_module = Utils.safe_popen_read("unzip", "-p", libexec/"obsidian-desktop-unsigned.hap", "module.json")
    module_json = JSON.parse(hap_module)
    requested = module_json.fetch("module").fetch("requestPermissions")
    %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.READ_WRITE_USER_FILE
       ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
       ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION
       ohos.permission.READ_PASTEBOARD].each do |name|
      requested << { "name" => name } unless requested.any? { |permission| permission["name"] == name }
    end
    # The tap checkout is read-only in CI; keep generated files in pkgshare.
    pkgshare.mkpath
    (pkgshare/"module-acl.json").write JSON.generate(module_json)

    # The HAP is delivered through app.json; deployment is explicit via
    # `ohos-app install obsidian-desktop`. The upstream CLI stays independent.
    (pkgshare/"ohos").mkpath
    hap = libexec/"obsidian-desktop-unsigned.hap"
    hap_sha = Digest::SHA256.file(hap).hexdigest
    descriptor = {
      "schema_version" => 1,
      "id"             => "social4hyq/core/obsidian-desktop",
      "artifact"       => {
        "format"       => "hap",
        "path"         => "../../../libexec/obsidian-desktop-unsigned.hap",
        "sha256"       => hap_sha,
        "api"          => 12,
        "abis"         => ["arm64-v8a"],
        "bundle_id"    => "com.social4hyq.obsidiandesktop",
        "version_name" => version.to_s,
        "version_code" => 1,
      },
      "launch"         => { "module" => "electron", "ability" => "EntryAbility" },
      "variants"       => {
        "default"     => "acl",
        "definitions" => {
          "basic" => {},
          "acl"   => { "module_overlay" => "module-acl.json",
                       "sha256"         => Digest::SHA256.file(pkgshare/"module-acl.json").hexdigest },
        },
      },
    }
    (pkgshare/"ohos/app.json").write JSON.pretty_generate(descriptor) + "\n"
  end

  test do
    # Only the HAP and descriptor are delivered; no app-level install command.
    refute_path_exists bin/"obsidian-app"

    descriptor = JSON.parse((pkgshare/"ohos/app.json").read)
    assert_equal 1, descriptor["schema_version"]
    assert_equal "social4hyq/core/obsidian-desktop", descriptor["id"]
    hap = libexec/"obsidian-desktop-unsigned.hap"
    assert_equal Digest::SHA256.file(hap).hexdigest, descriptor.dig("artifact", "sha256")
    assert_equal "com.social4hyq.obsidiandesktop", descriptor.dig("artifact", "bundle_id")
    assert_equal "acl", descriptor.dig("variants", "default")
    assert_equal Digest::SHA256.file(pkgshare/"module-acl.json").hexdigest,
                 descriptor.dig("variants", "definitions", "acl", "sha256")

    listing = shell_output("unzip -Z1 #{hap}")
    assert_match "libs/arm64-v8a/libelectron.so", listing
    assert_match "resources/resfile/resources/app/bootstrap.cjs", listing
    assert_match "resources/resfile/resources/app/node_modules/@electron/remote/main/index.js", listing
    refute_match "obsidian.asar", listing
    assert_match "com.social4hyq.obsidiandesktop", shell_output("unzip -p #{hap} module.json")
    system "unzip", "-tq", hap

    acl = JSON.parse((pkgshare/"module-acl.json").read)
    acl_permissions = acl.fetch("module").fetch("requestPermissions").map { |permission| permission.fetch("name") }
    assert_equal %w[ohos.permission.CUSTOM_SANDBOX ohos.permission.GET_NETWORK_INFO
                    ohos.permission.INTERNET ohos.permission.MICROPHONE ohos.permission.READ_PASTEBOARD
                    ohos.permission.READ_WRITE_USER_FILE
                    ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY
                    ohos.permission.kernel.DISABLE_CODE_MEMORY_PROTECTION].sort,
                 acl_permissions.sort
  end
end
