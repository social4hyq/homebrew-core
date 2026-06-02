class Dalfox < Formula
  desc "XSS scanner and utility focused on automation"
  homepage "https://dalfox.hahwul.com"
  url "https://github.com/hahwul/dalfox/archive/refs/tags/v3.0.2.tar.gz"
  sha256 "5e9429db49cbf5742555e0e4cca1f9fbe507c3979bba7685ea78db937ca7be92"
  license "MIT"
  head "https://github.com/hahwul/dalfox.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9c41310cdcbce2e3bc75f3216e42d9452d505a58e7c66a77165f119aeadd7f34"
  end

  depends_on "rust" => :build
  depends_on "cmake" => :build

  def install
    ENV["AWS_LC_SYS_NO_JITTER_ENTROPY"] = "1"
    system "cargo", "install", *std_cargo_args
  end

  test do
    # Development container doesn't have /system/lib64/ndk,
    # but the library exists in the OHOS SDK sysroot
    ENV.prepend_path "LD_LIBRARY_PATH", "/opt/ohos-sdk/ohos/native/sysroot/usr/lib/aarch64-linux-ohos"
    assert_match version.to_s, shell_output("#{bin}/dalfox -V 2>&1")

    url = "https://pentest-ground.com:4280/vulnerabilities/xss_r/"
    output = shell_output("#{bin}/dalfox scan \"#{url}\" 2>&1", 1)
    assert_match "scan completed", output
  end
end
