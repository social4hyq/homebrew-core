class Qrkey < Formula
  desc "Generate and recover QR codes from files for offline private key backup"
  homepage "https://github.com/Techwolf12/qrkey"
  url "https://github.com/Techwolf12/qrkey/archive/refs/tags/v0.0.1.tar.gz"
  sha256 "7c1777245e44014d53046383a96c1ee02b3ac1a4b014725a61ae707a79b7e82d"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c807804fc15e84d6d8b82978af93cef0fb13230de8b6e0e806f6da1091fd02ed"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
    generate_completions_from_executable(bin/"qrkey", shell_parameter_format: :cobra)
  end

  test do
    system bin/"qrkey", "generate", "--in", test_fixtures("test.jpg"), "--out", "generated.pdf"
    assert_path_exists testpath/"generated.pdf"
  end
end
