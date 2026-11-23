class AppInstaller < Formula
  desc "Sign and install OpenHarmony HAP packages"
  homepage "https://www.npmjs.com/package/@deveco/deveco-cli-openharmony-arm64"
  url "https://registry.npmjs.org/@deveco/deveco-cli-openharmony-arm64/-/deveco-cli-openharmony-arm64-1.3.12.tgz"
  sha256 "eaa29900d4892e89b2ae6156733ffa97597971b7a26fa1df6c686cc5934a02fb"
  license "MIT"
  revision 6

  livecheck do
    url :stable
    strategy :npm
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/app-installer-v1.3.12-r8"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2c1181ae190d2716d879830c6ad9f7e205fc632c19154121808a65c88773af5b"
  end

  depends_on "bash"
  depends_on "node"
  depends_on "ohos-sdk-toolchains"
  depends_on "unzip"

  # List every path literally: the weekly remove-unused-patches job keeps a
  # Resources/ directory only while a formula names it.
  RESOURCE_FILES = %w[
    Resources/app-installer/app-installer.sh
    Resources/app-installer/check-permissions.cjs
    Resources/app-installer/deveco-decoder.cjs
    Resources/app-installer/hap-app.sh
    Resources/app-installer/package-lock.json
    Resources/app-installer/prepare-profile.cjs
    Resources/app-installer/sign-hap.cjs
    Resources/app-installer/test-deveco-decoder.cjs
    Resources/app-installer/test-hap-app.cjs
    Resources/app-installer/test-install.cjs
  ].freeze

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    res = tap_root/"Resources/app-installer"
    RESOURCE_FILES.each do |file|
      odie "missing tap resource: #{file}" unless (tap_root/file).exist?
    end

    cli_source = buildpath.parent/"deveco-cli-runtime"
    cli_source.mkpath
    cli_package = buildpath
    cli_package_info = JSON.parse((cli_package/"package.json").read)
    package_name = "app-installer-deveco-cli-runtime"
    (cli_source/"package.json").write JSON.pretty_generate(
      "name"                 => package_name,
      "private"              => true,
      "dependencies"         => cli_package_info.fetch("dependencies"),
      "optionalDependencies" => cli_package_info.fetch("optionalDependencies", {}),
    )
    lock = JSON.parse((res/"package-lock.json").read)
    lock["name"] = package_name
    lock_root = lock.fetch("packages").fetch("")
    lock_root["name"] = package_name
    lock_root.delete("version")
    lock_root["dependencies"] = cli_package_info.fetch("dependencies")
    lock_root["optionalDependencies"] = cli_package_info.fetch("optionalDependencies", {})
    lock.fetch("packages").delete("node_modules/@deveco/deveco-cli-openharmony-arm64")
    (cli_source/"package-lock.json").write JSON.pretty_generate(lock) + "\n"
    system "npm", "ci", "--prefix", cli_source,
           "--omit=dev", "--ignore-scripts", "--no-audit", "--no-fund"
    axios = cli_source/"node_modules/axios/lib/adapters/http.js"
    inreplace axios,
              "throw new AxiosError('Invalid proxy authorization', AxiosError.ERR_BAD_OPTION, { proxy });",
              "proxyAuth = false;"
    cli_module = cli_source/"node_modules/@deveco/deveco-cli-openharmony-arm64"
    cli_module.dirname.mkpath
    cp_r cli_package, cli_module
    libexec.install cli_source/"node_modules"
    cli_js = libexec/"node_modules/@deveco/deveco-cli-openharmony-arm64/dist/cli.js"
    chmod 0755, cli_js

    toolchain = libexec/"app-installer-toolchain"
    toolchain_node = toolchain/"node/bin/node"
    toolchain_node.dirname.mkpath
    toolchain_node.write_env_script formula_opt_bin("node")/"node", {}
    ohpm = toolchain/"ohpm/bin/pm-cli.js"
    ohpm.dirname.mkpath
    ohpm.write <<~JS
      console.error("This toolchain adapter supports HAP signing only.");
      process.exit(1);
    JS
    hvigor = toolchain/"hvigor/bin/hvigorw.js"
    hvigor.dirname.mkpath
    hvigor.write <<~JS
      console.error("This toolchain adapter supports HAP signing only.");
      process.exit(1);
    JS
    sdk = toolchain/"sdk/default/openharmony"
    sdk_tools = formula_opt_prefix("ohos-sdk-toolchains")
    metadata = sdk/"toolchains/oh-uni-package.json"
    metadata.dirname.mkpath
    cp sdk_tools/"oh-uni-package.json", metadata
    sdk_info = JSON.parse(metadata.read)
    (toolchain/"sdk/default/sdk-pkg.json").write JSON.generate("data" => sdk_info)
    (sdk/"toolchains/hdc").write_env_script sdk_tools/"hdc", {}
    signer = sdk/"toolchains/lib/hap-sign-tool"
    signer.dirname.mkpath
    signer.write_env_script sdk_tools/"lib/hap-sign-tool", {}
    # Both spellings: `signature generate` reads the lowercase one on
    # case-sensitive filesystems.
    cp sdk_tools/"lib/PermissionDefinitions.json", sdk/"toolchains/lib/PermissionDefinitions.json"
    cp sdk_tools/"lib/PermissionDefinitions.json", sdk/"toolchains/lib/permissionDefinitions.json"

    cp res/"app-installer.sh", libexec/"app-installer.sh"
    cp res/"sign-hap.cjs", libexec/"sign-hap.cjs"
    cp res/"deveco-decoder.cjs", libexec/"deveco-decoder.cjs"
    cp res/"prepare-profile.cjs", libexec/"prepare-profile.cjs"
    cp res/"test-install.cjs", libexec/"test-install.cjs"
    cp res/"test-deveco-decoder.cjs", libexec/"test-deveco-decoder.cjs"
    cp res/"test-hap-app.cjs", libexec/"test-hap-app.cjs"
    cp res/"check-permissions.cjs", libexec/"check-permissions.cjs"
    cp res/"hap-app.sh", libexec/"hap-app.sh"
    chmod 0755, libexec/"app-installer.sh"
    chmod 0755, libexec/"sign-hap.cjs"
    chmod 0755, libexec/"check-permissions.cjs"
    chmod 0755, libexec/"hap-app.sh"
    cli_wrapper = libexec/"devecocli.sh"
    cli_wrapper.write <<~SH
      #!/bin/sh
      exec node "$DEVECO_CLI_JS" "$@"
    SH
    chmod 0755, cli_wrapper
    # Bare `devecocli` needs the bundled toolchain; otherwise ToolProvider
    # reports "No toolchain found" when no system CLT is installed.
    (bin/"devecocli").write_env_script cli_wrapper,
      COMMAND_LINE_TOOL_PATH: toolchain,
      DEVECO_CLI_JS:          cli_js,
      PATH:                   "#{formula_opt_bin("node")}:$PATH"
    (bin/"app-installer-sign").write_env_script libexec/"sign-hap.cjs",
      DEVECO_CLI_JS: cli_js,
      HAP_SIGN_TOOL: sdk_tools/"lib/hap-sign-tool",
      PATH:          "#{formula_opt_bin("node")}:$PATH"
    installer_path = [
      formula_opt_bin("node"),
      formula_opt_bin("bash"),
      sdk/"toolchains",
      sdk_tools,
      "$PATH",
    ].join(":")
    (bin/"app-installer").write_env_script libexec/"app-installer.sh",
      COMMAND_LINE_TOOL_PATH:         toolchain,
      DEVECO_CLI_JS:                  cli_js,
      HAP_INSTALLER_SIGNER:           libexec/"sign-hap.cjs",
      HAP_INSTALLER_PERMISSIONS:      sdk/"toolchains/lib/PermissionDefinitions.json",
      HAP_INSTALLER_PERMISSIONS_TOOL: libexec/"check-permissions.cjs",
      HAP_SIGN_TOOL:                  sdk_tools/"lib/hap-sign-tool",
      PATH:                           installer_path
    # The post-install entry point; HOMEBREW_PREFIX/bin is on PATH for brew's
    # minimal post_install environment.
    (bin/"hap-app").write_env_script libexec/"hap-app.sh",
      HAP_APP_APP_INSTALLER: opt_bin/"app-installer",
      PATH:                  "#{HOMEBREW_PREFIX}/bin:#{formula_opt_bin("node")}:#{formula_opt_bin("bash")}:$PATH"
    bin.install_symlink bin/"app-installer" => "hap-installer"
    bin.install_symlink bin/"app-installer-sign" => "hap-installer-sign"
  end

  def caveats
    <<~EOS
      The debug profile app-installer signs with is tied to this device and
      expires. Run `app-installer doctor` (or `hap-app doctor`) to see how many
      days are left, whether hdc and the Huawei Developer login are ready, and
      whether the bundled DevEco CLI password decoder is compatible; add
      `--network` to probe the signing endpoint with the configured TLS settings.

      The first login to the Huawei Developer account opens the login page in
      your default browser through `aa start`; pass `--no-browser` to open the
      printed link yourself.

      `app-installer --sign-only` writes a signed HAP without needing a device,
      and `--keystore` signs with your own certificate instead of logging in.
      System sideloading is not used yet: installs go through hdc.

      The tap's desktop apps install themselves after `brew install` through
      `hap-app`. A missing Huawei Developer login opens the browser and waits
      up to 120 seconds by default; set HAP_APP_AUTO_LOGIN=0 or auto_login=0 in
      ~/.config/hap-app/config to disable that. If the device is not ready or
      login is not completed, apps are queued: `hap-app status` lists them and
      `hap-app install-pending` finishes them. Each install refreshes the local
      debug profile before signing; a refresh failure also queues the app.

      Behind a proxy or VPN that intercepts HTTPS, signing needs the proxy CA:
      put `tls_ca=/path/to/ca.pem` in ~/.app-installer/config. Set
      `https_proxy=...` and optional `no_proxy=...` there to control network
      access for both DevEco signing and app vendor downloads during
      post-install; settings already present in your shell take precedence.
      Homebrew clears shell variables for
      post-install steps, so the file is the persistent configuration channel.
      Each automatic install prints concise preparation, signing, device and
      permission stages. The full output is in ~/.cache/hap-app/logs/; use
      `hap-app logs <app-command>` to read one app's latest log, or set
      HAP_APP_VERBOSE=1 to stream all output during installation.
    EOS
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "Usage: app-installer", shell_output("#{bin}/hap-installer --help")
    assert_match "Usage: sign-hap.cjs", shell_output("#{bin}/hap-installer-sign --help")
    assert_match "Usage: app-installer", shell_output("#{bin}/app-installer --help")
    assert_match "--bundle-id", shell_output("#{bin}/app-installer --help")
    assert_match "Usage: sign-hap.cjs", shell_output("#{bin}/app-installer-sign --help")
    assert_match "DevEco CLI decoder compatible", shell_output("#{bin}/app-installer-sign --check-decoder")
    %w[logs doctor install-pending].each do |command|
      assert_match command, shell_output("#{bin}/hap-app --help")
    end
    assert_match "Authentication commands", shell_output("#{bin}/devecocli auth --help")
    assert_match "COMMAND_LINE_TOOL_PATH=", (bin/"devecocli").read
    assert_match "--profile <path>", shell_output("#{bin}/app-installer --help")
    %w[--sign-only --method --keystore --no-browser uninstall doctor --purge].each do |option|
      assert_match option, shell_output("#{bin}/app-installer --help")
    end
    assert_match "uninstall --bundle-id <id> [--device <id>] [--hdc <path>] [--purge]",
                 shell_output("#{bin}/app-installer --help")
    assert_match "--keystore <p12>", shell_output("#{bin}/app-installer-sign --help")
    assert_match 'signed_hap="${signed_hap:-${TMPDIR:-$home/.cache}/app-installer/signed/$bundle_id.hap}"',
                 (libexec/"app-installer.sh").read
    assert_match "app-installer-toolchain/sdk/default/openharmony/toolchains", (bin/"app-installer").read
    assert_path_exists libexec/"app-installer-toolchain/sdk/default/openharmony/toolchains/hdc"
    %w[PermissionDefinitions.json permissionDefinitions.json].each do |name|
      assert_path_exists libexec/"app-installer-toolchain/sdk/default/openharmony/toolchains/lib"/name
    end
    ENV["DEVECO_CLI_JS"] = (libexec/"node_modules/@deveco/deveco-cli-openharmony-arm64/dist/cli.js").to_s
    system formula_opt_bin("node")/"node", "--test", libexec/"test-install.cjs",
           libexec/"test-hap-app.cjs", libexec/"test-deveco-decoder.cjs"
    refute_path_exists bin/"hdc"
    assert_match(/else if \(authIsObject\) \{\s+proxyAuth = false;/,
                 (libexec/"node_modules/axios/lib/adapters/http.js").read)
    assert_match "Usage: app-installer", shell_output("#{bin}/app-installer 2>&1", 2)
  end
end
