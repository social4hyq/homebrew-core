class Silicon < Formula
  desc "Create beautiful image of your source code"
  homepage "https://github.com/Aloxaf/silicon/"
  url "https://github.com/Aloxaf/silicon/archive/refs/tags/v0.5.3.tar.gz"
  sha256 "56e7f3be4118320b64e37a174cc2294484e27b019c59908c0a96680a5ae3ad58"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2bc94cbd3a5ada7c71b8241467c8e0dbaa19506109f0ac968bd2d3706ae9e1e1"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "harfbuzz"

  on_linux do
    depends_on "libxcb"
    depends_on "xclip"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"test.rs").write <<~RUST
      fn factorial(n: u64) -> u64 {
          match n {
              0 => 1,
              _ => n * factorial(n - 1),
          }
      }

      fn main() {
          println!("10! = {}", factorial(10));
      }
    RUST

    system bin/"silicon", "-o", "output.png", "test.rs"
    assert_path_exists testpath/"output.png"
    expected_size = [894, 630]
    assert_equal expected_size, File.read("output.png")[0x10..0x18].unpack("NN")
  end
end
