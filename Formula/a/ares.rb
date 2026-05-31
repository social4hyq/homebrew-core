class Ares < Formula
  desc "Automated decoding of encrypted text"
  homepage "https://github.com/bee-san/Ares"
  url "https://github.com/bee-san/Ares/archive/refs/tags/0.11.0.tar.gz"
  sha256 "fd8751de6c46eb523d62d4ca52018b9127b9fa5fbd4a372b7f22e0f9957f030f"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21e7c0490a62bd13f23a12f94514854b29457592bcd7ee8a190139cdfc5458af"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    # base64 encoded string for "Hello from Homebrew"
    input_string = "SGVsbG8gZnJvbSBIb21lYnJldw=="
    expected_text = "Hello from Homebrew"
    # Disable custom color scheme
    output = pipe_output("#{bin}/ares -d -t #{input_string}", "N", 0)
    assert_match expected_text, output
  end
end
