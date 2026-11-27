class OhosHap < Formula
  desc "Sign, verify and inspect OpenHarmony HAP packages (L0 contract v1)"
  homepage "https://github.com/social4hyq/homebrew-core"
  # This is a Resources-delivered contract driver (like the tap's claude-code
  # runtime-fetch stub): install() copies scripts from the checked-out tap, not
  # from the downloaded tarball. The fork's brew mandates a REAL sha256 (it
  # rejects :no_check), so pin a fixed, already-merged commit archive rather
  # than the moving `main.tar.gz`. The archive content is irrelevant to install.
  url "https://github.com/social4hyq/homebrew-core/archive/4edfd66476daa65e07f751d57ec623d486faaf07.tar.gz"
  version "1.0.0"
  sha256 "bd48e6006801d1a4211837bb38b729d3ccf868acdca2831d27a5cab6cfefac53"
  license "MIT"

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/ohos-hap-v1.0.0-r3"
    rebuild 2
    sha256 cellar: :any_skip_relocation, arm64_ohos: "52db4f8dfd76031a48b738a800007eee6cf2bdb097aa0c27ca8bb84ea3cc439c"
  end

  depends_on "node"
  depends_on "unzip" # inspect reads module.json from the final signed HAP

  # The DevEco signing runtime (npm) and hap-sign-tool are supplied by
  # ohos-sdk-toolchains / the CI image. This formula only ships the contract
  # driver; it never touches devices, app descriptors, host configs or login.
  RESOURCE_FILES = %w[
    Resources/ohos-hap/ohos-hap.cjs
    Resources/ohos-hap/lib/deveco-decoder.cjs
    Resources/ohos-hap/lib/prepare-profile.cjs
    Resources/ohos-hap/test-ohos-hap.cjs
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
    (bin/"ohos-hap").write_env_script libexec/"ohos-hap/ohos-hap.cjs",
      PATH: "#{formula_opt_bin("node")}:$PATH"
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
