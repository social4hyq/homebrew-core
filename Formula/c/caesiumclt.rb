class Caesiumclt < Formula
  desc "Fast and efficient lossy and/or lossless image compression tool"
  homepage "https://github.com/Lymphatus/caesium-clt"
  url "https://github.com/Lymphatus/caesium-clt/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "c170c4d1ab1179b3757ec39f00c08250b121195e07f013fcbf9f3952db333a05"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "62f3f7e36100d7d6af9b27dd682f1cda0a5b826662a1a4aff26335f170dc30ff"
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
