class Monolith < Formula
  desc "CLI tool for saving complete web pages as a single HTML file"
  homepage "https://github.com/Y2Z/monolith"
  url "https://github.com/Y2Z/monolith/archive/refs/tags/v2.10.1.tar.gz"
  sha256 "1afafc94ba693597f591206938e998fcf2c78fd6695e7dfd8c19e91061f7b44a"
  license "CC0-1.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "86947847ca72beca2d5b2c7b3dd27d0cf0543ae99b5ae3063092f99b51a38112"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system bin/"monolith", "https://lyrics.github.io/db/P/Portishead/Dummy/Roads/"
  end
end
