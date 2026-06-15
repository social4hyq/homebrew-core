class Dalfox < Formula
  desc "XSS scanner and utility focused on automation"
  homepage "https://dalfox.hahwul.com"
  url "https://github.com/hahwul/dalfox/archive/refs/tags/v3.1.0.tar.gz"
  sha256 "48cb44ef215d8905135e36cf27605c5a5addf3123cff29ca48e11f95c681c6ee"
  license "MIT"
  head "https://github.com/hahwul/dalfox.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "722c8ef0edfe1cf68fcedcc60924e60d91d71eaa6e68ebf1176ee2066a6980e2"
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
