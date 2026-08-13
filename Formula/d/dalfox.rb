class Dalfox < Formula
  desc "XSS scanner and utility focused on automation"
  homepage "https://dalfox.hahwul.com"
  url "https://github.com/hahwul/dalfox/archive/refs/tags/v3.2.1.tar.gz"
  sha256 "6b3b09be44dcfa00e15fded2999ccbaf7cae53b8cfa6ea7ce191f27d6c209c9b"
  license "MIT"
  head "https://github.com/hahwul/dalfox.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "156deb43638bdce7bd91410a93036256189882bd741166202d0008db89878479"
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
