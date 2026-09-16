class Dalfox < Formula
  desc "XSS scanner and utility focused on automation"
  homepage "https://dalfox.hahwul.com"
  url "https://github.com/hahwul/dalfox/archive/refs/tags/v3.2.3.tar.gz"
  sha256 "05a9d84ba549cc92516f7c3c488d8e60cd34fc47f58f55e734db4091e249079c"
  license "MIT"
  head "https://github.com/hahwul/dalfox.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1e56074640f5de003ffad781eab3acbc30f3cd630f781df32cc586a7b7456f79"
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
