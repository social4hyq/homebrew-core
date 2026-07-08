class Caesiumclt < Formula
  desc "Fast and efficient lossy and/or lossless image compression tool"
  homepage "https://github.com/Lymphatus/caesium-clt"
  url "https://github.com/Lymphatus/caesium-clt/archive/refs/tags/v1.4.0.tar.gz"
  sha256 "3dc4bc062536fcaa368d044aea873afd695feeabd9310d6118a7d45b2f0ad52e"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "29afd358c1a13cca14541694e413ea31d59c5d93e912c977ce3dbf9726ca1ce6"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system bin/"caesiumclt", "--lossless", "-Q", "--suffix", "_t", "--output", testpath, test_fixtures("test.jpg")
    assert_path_exists testpath/"test_t.jpg"
    system bin/"caesiumclt", "-q", "80", "-Q", "--suffix", "_b", "--output", testpath, test_fixtures("test.jpg")
    assert_path_exists testpath/"test_b.jpg"
  end
end
