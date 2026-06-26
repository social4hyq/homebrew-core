class Termframe < Formula
  desc "Terminal output SVG screenshot tool"
  homepage "https://github.com/pamburus/termframe"
  url "https://github.com/pamburus/termframe/archive/refs/tags/v0.8.7.tar.gz"
  sha256 "25d60c50c8f5022434ddd04ada7cd7334c61eb55efb735b052e1489e26293cde"
  license "MIT"
  head "https://github.com/pamburus/termframe.git", branch: "main"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4b17160a99d8c198cdb8a84729f95d69718df581db8ea2fc9eb019f4d82fe58d"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system bin/"termframe", "-o", "hello.svg", "--", "echo", "Hello, World"
    assert_path_exists testpath/"hello.svg"
  end
end
