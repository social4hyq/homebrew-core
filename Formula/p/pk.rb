class Pk < Formula
  desc "Field extractor command-line utility"
  homepage "https://github.com/johnmorrow/pk"
  url "https://github.com/johnmorrow/pk/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "e1d70b683cbf8d1be505e818d91ef07c6938c82affc914eaf88f25d4f81edd56"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8688c3b6443f7ce07a1024c49106c8f74ea38dfb432755a5c2237dec41d130f7"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "doc/pk.1"
  end

  test do
    assert_equal "B C D", pipe_output("#{bin}/pk 2..4", "A B C D E", 0).chomp
  end
end
