class OhosApp < Formula
  desc "Orchestrate explicit OpenHarmony HAP app deployment (L0 v1)"
  homepage "https://github.com/social4hyq/homebrew-core"
  # Resources-delivered driver (cf. claude-code / ohos-hap / ohos-device):
  # install() copies from the checked-out tap, not the tarball. Fork brew
  # mandates a real sha256; pin a fixed already-merged commit archive.
  url "https://github.com/social4hyq/homebrew-core/archive/977e355d9b424e8fa404eacd3cc9ca8427d99161.tar.gz"
  version "1.0.0"
  sha256 "0f37124f93b2431ebba47ba7f8f91ceb8ec2324c02ae6689399aa5359e9b3a7e"
  license "MIT"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-app-v1.0.0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "613fc338ceb3b040dcc587a56753804435733bba53a66eced7770891b0be5a7f"
  end

  depends_on "node"
  depends_on "ohos-device"
  depends_on "ohos-hap"

  # 20 L0 schemas projected from the single authoritative contract root,
  # plus the driver, test, and contract fingerprint. Literal paths are required
  # by the tap's check-hap-formulae.py (orphan-resource audit).
  RESOURCE_FILES = %w[
    Resources/ohos-app/ohos-app.cjs
    Resources/ohos-app/test-ohos-app.cjs
    Resources/ohos-app/schemas/v1/CONTRACT.sha256
    Resources/ohos-app/schemas/v1/app.schema.json
    Resources/ohos-app/schemas/v1/assembler.schema.json
    Resources/ohos-app/schemas/v1/assembly-request.schema.json
    Resources/ohos-app/schemas/v1/assembly-result.schema.json
    Resources/ohos-app/schemas/v1/backend-capabilities.schema.json
    Resources/ohos-app/schemas/v1/device-contract.schema.json
    Resources/ohos-app/schemas/v1/fetch-request.schema.json
    Resources/ohos-app/schemas/v1/fetch-result.schema.json
    Resources/ohos-app/schemas/v1/host-integration.schema.json
    Resources/ohos-app/schemas/v1/inspect-result.schema.json
    Resources/ohos-app/schemas/v1/install-event.schema.json
    Resources/ohos-app/schemas/v1/install-request.schema.json
    Resources/ohos-app/schemas/v1/install-result.schema.json
    Resources/ohos-app/schemas/v1/install-state.schema.json
    Resources/ohos-app/schemas/v1/personalizer.schema.json
    Resources/ohos-app/schemas/v1/plugin-descriptor.schema.json
    Resources/ohos-app/schemas/v1/request.schema.json
    Resources/ohos-app/schemas/v1/result.schema.json
    Resources/ohos-app/schemas/v1/sources-lock.schema.json
    Resources/ohos-app/schemas/v1/typed-assembly-config.schema.json
  ].freeze

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    RESOURCE_FILES.each do |file|
      odie "missing tap resource: #{file}" unless (tap_root/file).exist?
      dst = libexec/"ohos-app"/Pathname(file).relative_path_from(Pathname("Resources/ohos-app"))
      dst.dirname.mkpath
      cp tap_root/file, dst
    end
    (bin/"ohos-app").write_env_script libexec/"ohos-app/ohos-app.cjs",
      PATH: "#{formula_opt_bin("node")}:$PATH"
  end

  def caveats
    <<~EOS
      ohos-app is the explicit deployment entry point — it never runs from brew
      post-install. `brew install <name>-desktop` only delivers files; run
        ohos-app install <name>-desktop
      to sign and deploy the HAP to a device. It does not launch the app unless
      --start is passed, and failures are non-zero (no pending queue, no retry).

      ohos-app only orchestrates: it reads the desktop formula's app.json
      descriptor and drives ohos-hap (sign) and ohos-device (install/uninstall/
      lifecycle) through their versioned L0 process contracts. It does NOT
      implement signing, device I/O, assembly, host-service management, or call
      any <app> install command — there is no loopback.

      Descriptors are discovered from $HOMEBREW_PREFIX/opt/*/share/*/ohos/app.json
      (no central registry). Uninstall keeps device data by default; --purge
      clears only device sandbox data.
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/ohos-app --help")
    # Orchestration contract tests use fake L3/L4 drivers; no device or signing.
    system formula_opt_bin("node")/"node", libexec/"ohos-app/test-ohos-app.cjs"
  end
end
