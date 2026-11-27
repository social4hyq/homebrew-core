class OhosDevice < Formula
  desc "Device operations for OpenHarmony HAP apps (hdc / sideload, L0 v1)"
  homepage "https://github.com/social4hyq/homebrew-core"
  # Resources-delivered contract driver (cf. claude-code / ohos-hap): install()
  # copies from the checked-out tap, not the tarball. Fork brew mandates a REAL
  # sha256, so pin a fixed, already-merged commit archive (content immutable).
  url "https://github.com/social4hyq/homebrew-core/archive/342331101ee41e2ed5d40b6f3f7773fbf7cd5f6f.tar.gz"
  version "1.0.0"
  sha256 "0197591a69264f82f0757fa6ff08754d2911dffb295f709dbedaa50a5d290b3d"
  license "MIT"

  depends_on "node"

  RESOURCE_FILES = %w[
    Resources/ohos-device/ohos-device.cjs
    Resources/ohos-device/test-ohos-device.cjs
    Resources/ohos-device/schemas/v1/backend-capabilities.schema.json
    Resources/ohos-device/schemas/v1/device-contract.schema.json
    Resources/ohos-device/schemas/v1/install-event.schema.json
    Resources/ohos-device/schemas/v1/install-request.schema.json
    Resources/ohos-device/schemas/v1/install-result.schema.json
    Resources/ohos-device/schemas/v1/install-state.schema.json
    Resources/ohos-device/schemas/v1/CONTRACT.sha256
  ].freeze

  def install
    tap_root = Pathname(__FILE__).expand_path.dirname.parent.parent
    RESOURCE_FILES.each { |file| odie "missing tap resource: #{file}" unless (tap_root/file).exist? }
    (libexec/"ohos-device").mkpath
    RESOURCE_FILES.each do |file|
      dst = libexec/"ohos-device"/Pathname(file).relative_path_from(Pathname("Resources/ohos-device"))
      dst.dirname.mkpath
      cp tap_root/file, dst
    end
    (bin/"ohos-device").write_env_script libexec/"ohos-device/ohos-device.cjs",
      PATH: "#{formula_opt_bin("node")}:$PATH"
  end

  def caveats
    <<~EOS
      ohos-device is the only component that talks to devices: hdc/bm/aa and the
      system sideload installer. It never signs, downloads, assembles, reads app
      descriptors, or manages host services.

      Install consumes the L0 InstallRequest contract; events are NDJSON with
      exactly one terminal install_result. --method is hdc|sideload|auto:
        - hdc: explicit, fails if no device; no fallback to sideload
        - sideload: fail-closed until the official system API is published
        - auto: prefers sideload only if available, else hdc; auto selection
          happens BEFORE any install action, never after a user confirmation

      The hdc binary is resolved from $HDC / $OHOS_DEVICE_HDC / PATH. Point $HDC
      at the ohos-sdk-toolchains hdc for real devices. Wait timeout is a local
      wait end, NOT an install failure; install-status is unsupported on the hdc
      backend (no fabricated pending database) — use status --bundle-id.

      Uninstall keeps user data by default (bm uninstall -k); --purge deletes
      only device sandbox data, never host config, tokens or CLI data.
    EOS
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/ohos-device --help")
    # Dual-backend contract tests use a fake hdc; no real device or sideload API.
    system formula_opt_bin("node")/"node", libexec/"ohos-device/test-ohos-device.cjs"
  end
end
