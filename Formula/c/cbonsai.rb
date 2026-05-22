class Cbonsai < Formula
  desc "Console Bonsai is a bonsai tree generator, written in C using ncurses"
  homepage "https://gitlab.com/jallbrit/cbonsai"
  url "https://gitlab.com/jallbrit/cbonsai/-/archive/v1.4.2/cbonsai-v1.4.2.tar.gz"
  sha256 "75cf844940e5ef825a74f2d5b1551fe81883551b600fecd00748c6aa325f5ab0"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b8259b9e2ca0ceabf63e0b47b610f0c66ce2348f6afbfceef0458e67cbc9b3c3"
  end

  depends_on "pkgconf" => :build
  depends_on "scdoc" => :build
  depends_on "ncurses"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"cbonsai", "-p"
  end
end
