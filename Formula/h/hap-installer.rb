class HapInstaller < Formula
  desc "Sign and install OpenHarmony HAP packages"
  homepage "https://www.npmjs.com/package/@deveco/deveco-cli-openharmony-arm64"
  url "https://registry.npmjs.org/@deveco/deveco-cli-openharmony-arm64/-/deveco-cli-openharmony-arm64-1.3.10.tgz"
  sha256 "7fdee1bfb7393c151fa09b3714ecc4796e53d9876557e9933c5890319ffb4daa"
  license "MIT"
  revision 1

  livecheck do
    url "https://registry.npmjs.org/@deveco%2Fdeveco-cli-openharmony-arm64"
    strategy :npm
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/hap-installer-v1.3.10-r2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "70cdb5186c1c93401ff6d382c3289d8f8d5d5a14ff87b34ed05ab4e4a7e12066"
  end

  depends_on "node"
  depends_on "ohos-sdk-toolchains"

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    payload = tap_root/"Patches/hap-installer"
    cli_source = buildpath.parent/"deveco-cli-runtime"
    cli_source.mkpath
    cli_package = buildpath
    cli_package_info = JSON.parse((cli_package/"package.json").read)
    package_name = "hap-installer-deveco-cli-runtime"
    (cli_source/"package.json").write JSON.pretty_generate(
      "name"                 => package_name,
      "private"              => true,
      "dependencies"         => cli_package_info.fetch("dependencies"),
      "optionalDependencies" => cli_package_info.fetch("optionalDependencies", {}),
    )
    lock = JSON.parse((payload/"package-lock.json").read)
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

    toolchain = libexec/"hap-installer-toolchain"
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

    cp payload/"hap-installer.sh", libexec/"hap-installer.sh"
    cp payload/"sign-hap.cjs", libexec/"sign-hap.cjs"
    chmod 0755, libexec/"hap-installer.sh"
    chmod 0755, libexec/"sign-hap.cjs"
    cli_wrapper = libexec/"devecocli.sh"
    cli_wrapper.write <<~SH
      #!/bin/sh
      exec node "$DEVECO_CLI_JS" "$@"
    SH
    chmod 0755, cli_wrapper
    (bin/"devecocli").write_env_script cli_wrapper,
      DEVECO_CLI_JS: cli_js,
      PATH:          "#{formula_opt_bin("node")}:$PATH"
    (bin/"hap-installer-sign").write_env_script libexec/"sign-hap.cjs",
      DEVECO_CLI_JS: cli_js,
      HAP_SIGN_TOOL: sdk_tools/"lib/hap-sign-tool",
      PATH:          "#{formula_opt_bin("node")}:$PATH"
    (bin/"hap-installer").write_env_script libexec/"hap-installer.sh",
      COMMAND_LINE_TOOL_PATH: toolchain,
      DEVECO_CLI_JS:          cli_js,
      HAP_INSTALLER_SIGNER:   libexec/"sign-hap.cjs",
      HAP_SIGN_TOOL:          sdk_tools/"lib/hap-sign-tool",
      PATH:                   "#{formula_opt_bin("node")}:#{sdk}/toolchains:#{sdk_tools}:$PATH"
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "Usage: hap-installer", shell_output("#{bin}/hap-installer --help")
    assert_match "--bundle-id", shell_output("#{bin}/hap-installer --help")
    assert_match "Usage: sign-hap.cjs", shell_output("#{bin}/hap-installer-sign --help")
    assert_match "Authentication commands", shell_output("#{bin}/devecocli auth --help")
    assert_match 'signed_hap="${signed_hap:-${TMPDIR:-$home/.cache}/hap-installer/signed/$bundle_id.hap}"',
                 (libexec/"hap-installer.sh").read
    assert_match "hap-installer-toolchain/sdk/default/openharmony/toolchains", (bin/"hap-installer").read
    assert_path_exists libexec/"hap-installer-toolchain/sdk/default/openharmony/toolchains/hdc"
    refute_path_exists bin/"hdc"
    assert_match(/else if \(authIsObject\) \{\s+proxyAuth = false;/,
                 (libexec/"node_modules/axios/lib/adapters/http.js").read)
    assert_match "Usage: hap-installer", shell_output("#{bin}/hap-installer 2>&1", 2)
  end
end
