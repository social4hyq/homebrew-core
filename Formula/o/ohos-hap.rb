class OhosHap < Formula
  desc "Sign, verify and inspect OpenHarmony HAP packages (L0 contract v1)"
  homepage "https://github.com/social4hyq/homebrew-core"
  # The tarball is the pinned DevEco CLI runtime; install() uses its package.json
  # to npm-ci the runtime into libexec (self-contained — no public devecocli
  # command). The L0 contract driver itself is delivered from Resources/ in the
  # tap checkout. Version tracks the contract (1.0.0), not the npm package.
  url "https://registry.npmjs.org/@deveco/deveco-cli-openharmony-arm64/-/deveco-cli-openharmony-arm64-1.3.10.tgz"
  version "1.0.0"
  sha256 "7fdee1bfb7393c151fa09b3714ecc4796e53d9876557e9933c5890319ffb4daa"
  license "MIT"
  revision 6

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-hap-v1.0.0-r12"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "78fe512374a3cb9a5da4ea112690c08fee10d3c9593f41433e517a5c0983c5eb"
  end

  depends_on "node"
  depends_on "ohos-sdk-toolchains" # hdc / hap-sign-tool / PermissionDefinitions for the vendor toolchain adapter
  depends_on "unzip" # inspect reads module.json from the final signed HAP

  # The DevEco signing runtime (npm) and hap-sign-tool are supplied by
  # ohos-sdk-toolchains / the CI image. This formula only ships the contract
  # driver; it never touches devices, app descriptors, host configs or login.
  RESOURCE_FILES = %w[
    Resources/ohos-hap/ohos-hap.cjs
    Resources/ohos-hap/lib/deveco-decoder.cjs
    Resources/ohos-hap/lib/prepare-profile.cjs
    Resources/ohos-hap/lib/vendor-auth.sh
    Resources/ohos-hap/lib/profile-refresh.sh
    Resources/ohos-hap/package-lock.json
    Resources/ohos-hap/test-ohos-hap.cjs
    Resources/ohos-hap/test-profile-refresh.cjs
    Resources/ohos-hap/schemas/v1/request.schema.json
    Resources/ohos-hap/schemas/v1/result.schema.json
    Resources/ohos-hap/schemas/v1/inspect-result.schema.json
    Resources/ohos-hap/schemas/v1/CONTRACT.sha256
  ].freeze

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }
    (libexec/"ohos-hap").mkpath
    RESOURCE_FILES.each do |file|
      dst = libexec/"ohos-hap"/Pathname(file).relative_path_from(Pathname("Resources/ohos-hap"))
      dst.dirname.mkpath
      cp tap_root/file, dst
    end

    # Self-contained DevEco CLI runtime (no public devecocli command). The
    # downloaded tarball is the npm package itself; its package.json supplies
    # dependencies and the checked-in lockfile pins the exact tree.
    cli_source = buildpath.parent/"deveco-runtime"
    cli_source.mkpath
    package_name = "ohos-hap-deveco-runtime"
    package_info = JSON.parse((buildpath/"package.json").read)
    runtime_package = {
      "name"                 => package_name,
      "private"              => true,
      "dependencies"         => package_info.fetch("dependencies"),
      "optionalDependencies" => package_info.fetch("optionalDependencies", {}),
    }
    (cli_source/"package.json").write JSON.pretty_generate(runtime_package)
    lock = JSON.parse((tap_root/"Resources/ohos-hap/package-lock.json").read)
    lock["name"] = package_name
    lock_root = lock.fetch("packages").fetch("")
    lock_root["name"] = package_name
    lock_root.delete("version")
    lock_root["dependencies"] = package_info.fetch("dependencies")
    lock_root["optionalDependencies"] = package_info.fetch("optionalDependencies", {})
    lock.fetch("packages").delete("node_modules/@deveco/deveco-cli-openharmony-arm64")
    (cli_source/"package-lock.json").write JSON.pretty_generate(lock) + "\n"
    system "npm", "ci", "--prefix", cli_source,
           "--omit=dev", "--ignore-scripts", "--no-audit", "--no-fund"

    # The CLI's axios proxy adapter mishandles proxy auth; patch it the same way
    # the legacy app-installer did (fail-closed proxy handling).
    axios = cli_source/"node_modules/axios/lib/adapters/http.js"
    inreplace axios,
              "throw new AxiosError('Invalid proxy authorization', AxiosError.ERR_BAD_OPTION, { proxy });",
              "proxyAuth = false;"

    cli_module = cli_source/"node_modules/@deveco/deveco-cli-openharmony-arm64"
    cli_module.dirname.mkpath
    cp_r buildpath, cli_module
    (libexec/"deveco-runtime").mkpath # install() renames into this parent
    libexec.install cli_source/"node_modules" => "deveco-runtime/node_modules"
    cli_js = libexec/"deveco-runtime/node_modules/@deveco/deveco-cli-openharmony-arm64/dist/cli.js"
    odie "DevEco CLI runtime missing" unless cli_js.file?
    chmod 0755, cli_js # invoked directly via its shebang by vendor-auth/profile-refresh

    # devecocli's signature generate needs a toolchain laid out the way its
    # ToolProvider expects. Build a signing-only adapter from ohos-sdk-toolchains:
    # node/ohpm/hvigor are stubbed (no build here), while hdc / hap-sign-tool /
    # PermissionDefinitions and the SDK metadata are real.
    toolchain = libexec/"deveco-toolchain"
    node_stub = toolchain/"node/bin/node"
    node_stub.dirname.mkpath
    node_stub.write_env_script formula_opt_bin("node")/"node", {}
    %w[ohpm/bin/pm-cli.js hvigor/bin/hvigorw.js].each do |entry|
      stub = toolchain/entry
      stub.dirname.mkpath
      stub.write <<~JS
        console.error("This toolchain adapter supports HAP signing only.");
        process.exit(1);
      JS
    end
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
    # signature generate reads the lowercase spelling on case-sensitive systems.
    cp sdk_tools/"lib/PermissionDefinitions.json", sdk/"toolchains/lib/PermissionDefinitions.json"
    cp sdk_tools/"lib/PermissionDefinitions.json", sdk/"toolchains/lib/permissionDefinitions.json"

    (bin/"ohos-hap").write_env_script libexec/"ohos-hap/ohos-hap.cjs",
      PATH: "#{formula_opt_bin("node")}:$PATH",
      OHOS_HAP_VENDOR_CLI: cli_js, DEVECO_CLI_JS: cli_js,
      COMMAND_LINE_TOOL_PATH: toolchain
  end

  def caveats
    <<~EOS
      ohos-hap signs/verifies/inspects HAP packages only — it never touches devices,
      app descriptors, host configs, or performs vendor login implicitly.

      Signing consumes the L0 SigningRequest contract:
        ohos-hap sign --request request.json [--result result.json] [--signer PATH]
      Signing profiles live at $XDG_CONFIG_HOME/ohos-hap/profiles.json (non-secret
      config); passwords are referenced by env:/file: secret refs, never inlined.

      PASSWORD RESIDUAL RISK (current SDK): hap-sign-tool's -pwdInputMode 1 is
      TTY-only (pipe/stdin fails with "failed to get keystorePwd"), so the
      automated path necessarily passes passwords in argv, briefly visible to
      processes of the same user. This is recorded, not eliminated; see
      docs/signing-argv-protection-findings.md. Prefer external keystore/profile
      material you control, and never enable implicit login.
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/ohos-hap --help")
    # Contract tests use a fake signer; no real DevEco CLI or device needed.
    system formula_opt_bin("node")/"node", libexec/"ohos-hap/test-ohos-hap.cjs"
  end
end
