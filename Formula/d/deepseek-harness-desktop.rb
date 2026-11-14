class DeepseekHarnessDesktop < Formula
  desc "Agent desktop shell with a host-side runtime bridge for OpenHarmony"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://github.com/deepseek-ai/deepseek-harness/archive/39163dd30f703a79079e2d2446545cff3c453738.tar.gz"
  version "0.2.2-rc.3"
  sha256 "f77ad662bf7d6875f01e34f69c9e1c5f4f306a4dd5265e663c2093fdf9957cc0"
  license "MIT"

  livecheck do
    url :stable
    regex(/^dsh-v?(\d+(?:\.\d+)+(?:-rc\.\d+)?)$/i)
    strategy :github_latest
  end

  depends_on "cmake" => :build
  depends_on "git" => :build
  depends_on "node" => :build
  depends_on "node@24" => :build
  depends_on "ohos-selfsign" => :build
  depends_on "pnpm" => :build
  depends_on "hap-installer"
  depends_on "ripgrep"

  # openharmony-sig/electron PC(2in1) prebuilt (CodeHub mirror hosted on this
  # tap's release; redistribution assumed by the tap owner, see ohos-multica).
  resource "electron-ohos" do
    url "https://github.com/social4hyq/homebrew-core/releases/download/electron-ohos-v34.9.0-20261030.1/v34.9.0-20261030.1-release.zip"
    sha256 "599e97b3d8b1e5071a2387496104b443e58079a5f5c165b0114e65ffc601df3a"
  end

  # DeepSeek's runtime-internals addon (HMR/app-boot). npm has no openharmony
  # variant; the NAPI v9 addon builds from source with the tree's own gyp file.
  resource "require-builtin" do
    url "https://github.com/deepseek-ai/dsh-node-addon-require-builtin/archive/a58d3599a2e551d7d706d1ff796c9fd4bbaff63c.tar.gz"
    sha256 "286616f15e4f12013988e45ad27a69b4968a9f059c8bd351e412505230577948"
  end

  # sharp's wasm fallback and its two runtime dependencies (no OHOS prebuilts).
  resource "sharp-wasm32" do
    url "https://registry.npmjs.org/@img/sharp-wasm32/-/sharp-wasm32-0.35.5.tgz"
    sha256 "c68abdf53e1ad2d7b27b53385a3862e16d4bde02ce6d121892ee36f0bfe5bb38"
  end

  resource "emnapi-runtime" do
    url "https://registry.npmjs.org/@emnapi/runtime/-/runtime-1.11.3.tgz"
    sha256 "e6eb8913a08b551436d65f9a5cfbdcc8006f58e6798226d24e695c25679b5e49"
  end

  resource "tslib" do
    url "https://registry.npmjs.org/tslib/-/tslib-2.8.1.tgz"
    sha256 "66f635d5eeabae44807534976913a102cf615b9a045368359c9f79ae6ee2119e"
  end

  patch :p1 do
    file "Patches/deepseek-harness-desktop/0001-pnpm-workspace-ohos.patch"
  end

  patch :p1 do
    file "Patches/deepseek-harness-desktop/0002-desktop-ohos-target.patch"
  end

  patch :p1 do
    file "Patches/deepseek-harness-desktop/0003-primary-runtime-ohos.patch"
  end

  patch :p1 do
    file "Patches/deepseek-harness-desktop/0004-runtime-assembly-ohos.patch"
  end

  patch :p1 do
    file "Patches/deepseek-harness-desktop/0005-shell-ohos.patch"
  end

  patch :p1 do
    file "Patches/deepseek-harness-desktop/0006-core-runtime-ohos.patch"
  end

  def install
    system "sh", "-c", "echo DSH_INSTALL_START; pwd; ls"
    patches = Pathname(__dir__)/"Patches/deepseek-harness-desktop"
    clt = Pathname.new("/opt/electron-ohos-clt")
    odie "deepseek-harness-desktop builds only in electron-ohos-ci; check OHOS_CI_IMAGE_OVERRIDES" unless
      (clt/"hvigor/bin/hvigorw.js").exist?

    target = "apps/desktop/.desktop-build/targets/openharmony-arm64"

    ENV["ELECTRON_SKIP_BINARY_DOWNLOAD"] = "1"
    ENV["CI"] = "true"
    ENV["DSH_DESKTOP_TARGET_PLATFORM"] = "openharmony"
    ENV["DSH_SIGN_TOOL"] = (formula_opt_bin("ohos-selfsign")/"selfsign").to_s
    ENV["DSH_SIGN_TOOL_MODE"] = "inplace"
    node24 = (formula_opt_bin("node@24")/"node").to_s
    ENV["DSH_OHOS_NODE_BINARY"] = node24

    system "pnpm", "install", "--frozen-lockfile", "--reporter=append-only"

    # Complete-build record for the client artifacts (pack-local-packages
    # insists on a full build's public environment; profile "local").
    system "pnpm", "exec", "tsx", "-e", <<~JS
      import { writeClientBuildRecord, repositoryClientBuildEnvironment, resolveClientBuildEnvironment } from "./scripts/client-build-environment.ts"
      const env = resolveClientBuildEnvironment(repositoryClientBuildEnvironment(process.cwd(), process.env), "local")
      writeClientBuildRecord(process.cwd(), env)
    JS

    system "pnpm", "run", "build:lib:host"
    system "pnpm", "run", "build:lib:client"
    system "pnpm", "run", "build:web"

    # Runtime package set: every workspace package plus the private Host entry.
    build = buildpath/target
    system "pnpm", "exec", "tsx", "apps/desktop/scripts/pack-local-packages.ts", "--out", build/"packed/dsh"
    system "pnpm", "--dir", "apps/desktop-host", "pack", "--pack-destination", build/"packed/dsh"
    system "pnpm", "run", "release:pack", "--family", "vendor", "--out", build/"packed/vendor"
    (build/"packed/landlock").mkpath
    system "pnpm", "--dir", "native/system", "run", "build:ts"
    system "pnpm", "--dir", "native/system/packages/entry", "pack",
           "--pack-destination", build/"packed/landlock"

    # OHOS-native packages injected into the runtime tree (loader resolves
    # "<name>-openharmony-arm64" first, then their local build paths).
    natives = buildpath/"ohos-native"
    natives.mkpath
    resource("require-builtin").stage do
      require_builtin = natives/"node-addon-require-builtin-openharmony-arm64"
      (require_builtin/"lib").mkpath
      (require_builtin/"index.js").write <<~JS
        'use strict';
        const { loadPrebuild } = require('node-addon-native-custom-loader');
        module.exports = loadPrebuild(__dirname);
      JS
      (require_builtin/"package.json").write <<~JSON
        {
          "name": "node-addon-require-builtin-openharmony-arm64",
          "version": "0.1.9",
          "main": "./index.js",
          "os": ["openharmony"],
          "cpu": ["arm64"],
          "engines": { "node": ">=20" },
          "files": ["index.js", "prebuilds.json", "prebuilt/"],
          "dependencies": { "node-addon-native-custom-loader": "0.1.9" },
          "license": "MIT"
        }
      JSON
      (require_builtin/"prebuilds.json").write <<~JSON
        {
          "platform": "openharmony-arm64",
          "binaries": [
            { "backend": "napi", "abi": "napi-v9", "binaryTag": "napi-v9", "node": ">=20",
              "path": "prebuilt/openharmony-arm64-napi-v9.node" }
          ]
        }
      JSON
      # node-addon-api for the gyp include path (isolated install, not the tree's).
      system "npm", "install", *std_npm_args(prefix: false), "--no-save", "node-addon-api@8"
      cd "packages/native" do
        system "npm", "exec", "--yes", "--", "node-gyp@11", "rebuild", "--", "-Dnarb_product=require-builtin"
        (require_builtin/"prebuilt").mkpath
        cp "build/Release/require_builtin.node", require_builtin/"prebuilt/openharmony-arm64-napi-v9.node"
      end
      loader = Pathname("node_modules/node-addon-native-custom-loader")
      (require_builtin/"node_modules").mkpath
      cp_r loader, require_builtin/"node_modules/node-addon-native-custom-loader"
    end
    { "sharp-wasm32" => "@img/sharp-wasm32", "emnapi-runtime" => "@emnapi/runtime", "tslib" => "tslib" }
      .each do |name, package_name|
      destination = natives/package_name
      destination.dirname.mkpath
      resource(name).stage { cp_r ".", destination.to_s }
    end
    ENV["DSH_OHOS_NATIVE_PACKAGES"] = [natives/"node-addon-require-builtin-openharmony-arm64",
                                       natives/"@img/sharp-wasm32", natives/"@emnapi/runtime",
                                       natives/"tslib"].join(":")

    system "pnpm", "--dir", "apps/desktop", "run", "prepare:runtime"
    system "pnpm", "--dir", "apps/desktop", "run", "prepare:packages"
    system "pnpm", "--dir", "apps/desktop", "run", "prepare:dsh", "--", "--defer-runtime-smoke"

    # ----- HAP shell (unsigned; hvigor runs in the private CI image) -----
    resource("electron-ohos").fetch
    system "unzip", "-o", resource("electron-ohos").cached_download, "-d", buildpath/"electron-prebuilt"
    system "tar", "-xzf", buildpath/"electron-prebuilt/libelectron_132.tar.gz",
           "-C", buildpath/"electron-prebuilt"
    shell = buildpath/"electron-prebuilt/libelectron/ohos_hap"

    # Branding: upstream icon + product name.
    icon = buildpath/"apps/desktop/resources/icon-macos.png"
    %w[app_icon.png startIcon.png].each { |name| cp icon, shell/"AppScope/resources/base/media"/name }
    label_keys = %w[EntryAbility_label StatusBarEntryAbility_label]
    %w[base en_US zh_CN].each do |locale|
      path = shell/"electron/src/main/resources"/locale/"element/string.json"
      manifest = JSON.parse(path.read)
      manifest["string"].each do |entry|
        entry["value"] = "DeepSeek Harness" if label_keys.include?(entry["name"])
      end
      path.write JSON.pretty_generate(manifest)
    end
    app_scope = shell/"AppScope/resources/base/element/string.json"
    scope = JSON.parse(app_scope.read)
    scope["string"].each { |entry| entry["value"] = "DeepSeek Harness" if entry["name"] == "app_name" }
    app_scope.write JSON.pretty_generate(scope)

    payload = shell/"web_engine/src/main/resources/resfile/resources"
    system "sh", patches/"assemble-payload.sh", buildpath.to_s, payload.to_s

    ENV["DEVECO_SDK_HOME"] = (clt/"sdk").to_s
    ENV["HOS_SDK_HOME"] = (clt/"sdk").to_s
    ENV["LD_LIBRARY_PATH"] =
      "#{clt}/lib:#{clt}/sdk/default/openharmony/native/llvm/lib/clang/15.0.4/lib/aarch64-linux-ohos"
    ENV.delete("NODE_OPTIONS")
    soft_cap, hard_cap = Process.getrlimit(Process::RLIMIT_NOFILE)
    Process.setrlimit(Process::RLIMIT_NOFILE, [soft_cap, 65_536].min, 65_536) if hard_cap > 65_536

    cd shell do
      system "node", clt/"ohpm/bin/pm-cli.js", "install"
      system "node", clt/"hvigor/bin/hvigorw.js", "assembleHap",
             "--mode", "module", "-p", "product=default", "--no-daemon"
    end

    # ----- install -----
    runtime = buildpath/target/"dsh"
    resources = buildpath/target/"runtime"
    (libexec/"runtime").mkpath
    libexec.install runtime => "runtime/dsh"
    libexec.install resources/"primary-runtime" => "runtime/primary-runtime"
    libexec.install resources/"bin" => "runtime/bin"
    libexec.install resources/"versions.json" => "runtime/versions.json"
    libexec.install resources/"cli" => "runtime/cli"
    libexec.install "bridge/dsh-desktop-bridge.mjs"
    (libexec/"bridge-wrapper.sh").write((patches/"bridge-wrapper.sh").read)
    chmod 0755, libexec/"bridge-wrapper.sh"
    (bin/"dsh-desktop-bridge").write_env_script libexec/"bridge-wrapper.sh",
      DSH_DESKTOP_BRIDGE_JS: libexec/"dsh-desktop-bridge.mjs",
      DSH_BRIDGE_NODE:       libexec/"runtime/primary-runtime/dependencies/node/bin/node"
    (pkgshare/"install-desktop.sh").write((patches/"install-desktop.sh").read)
    chmod 0755, pkgshare/"install-desktop.sh"
    (bin/"dsh-install-desktop").write_env_script pkgshare/"install-desktop.sh",
      DSH_DESKTOP_UNSIGNED_HAP: libexec/"dsh-desktop-unsigned.hap"
    libexec.install shell/"electron/build/default/outputs/default/electron-default-unsigned.hap" =>
                     "dsh-desktop-unsigned.hap"
  end

  def caveats
    <<~EOS
      The desktop HAP is unsigned in the bottle: #{opt_libexec}/dsh-desktop-unsigned.hap
      Connect and unlock the device, then run:

        dsh-desktop-bridge          # host-side runtime bridge (also: add to ~/.shellrc)
        dsh-install-desktop         # sign + install + launch through hap-installer

      Signing material stays under your home directory; it is not in the bottle.
      Upgrades go through Harmonybrew (`brew upgrade deepseek-harness-desktop`).
    EOS
  end

  test do
    assert_path_exists libexec/"dsh-desktop-unsigned.hap"
    (testpath/"home").mkpath
    ENV["HOME"] = testpath/"home"
    ENV["DSH_BRIDGE_STATE_DIR"] = testpath/"state"
    assert_path_exists libexec/"dsh-desktop-bridge.mjs"
    assert_path_exists libexec/"runtime/primary-runtime/dependencies/node/bin/node"
    assert_path_exists libexec/"runtime/dsh/desktop-runtime.json"
    listing = shell_output("unzip -l #{libexec}/dsh-desktop-unsigned.hap")
    assert_match "module.json", listing
    assert_match "resources/resfile/resources/app/lib/main.js", listing
    assert_match "resources/resfile/resources/app/dsh/node_modules/@deepseek-ai/dsh-web-frontend/dist", listing
    package_json = "resources/resfile/resources/app/package.json"
    package = JSON.parse(shell_output("unzip -p #{libexec}/dsh-desktop-unsigned.hap #{package_json}"))
    assert_equal "0.2.2-rc.3", package.fetch("version")
  end
end
