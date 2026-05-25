class Lutgen < Formula
  desc "Blazingly fast interpolated LUT generator and applicator for color palettes"
  homepage "https://ozwaldorf.github.io/lutgen-rs/"
  url "https://github.com/ozwaldorf/lutgen-rs/archive/refs/tags/lutgen-v1.1.1.tar.gz"
  sha256 "86f65213c8ada58eee5b2e4113db5c6eeebf537356c2c62cd2bf5c3f1c8c7255"
  license "MIT"
  head "https://github.com/ozwaldorf/lutgen-rs.git", branch: "main"

  livecheck do
    url :stable
    regex(/^(?:lutgen[._-])?v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "28864feee7359542faad5ced5d0325ac59756b385db69e3861cefb4b32a01655"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/cli")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/lutgen --version")

    cp test_fixtures("test.png"), testpath/"test.png"
    system bin/"lutgen", "apply", "--palette", "gruvbox-dark", "-o", "result.png", "test.png"
    assert_path_exists testpath/"result.png"
  end
end
