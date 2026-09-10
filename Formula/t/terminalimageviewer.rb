class Terminalimageviewer < Formula
  desc "Display images in a terminal using block graphic characters"
  homepage "https://github.com/stefanhaustein/TerminalImageViewer"
  url "https://github.com/stefanhaustein/TerminalImageViewer/archive/refs/tags/v1.2.1.tar.gz"
  sha256 "08d0c30e3ffa47b69d1bce07bea56f04b7deb4a8a79307ce435a4f0852fbcd5f"
  license "Apache-2.0"
  revision 1
  head "https://github.com/stefanhaustein/TerminalImageViewer.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "36855b28a5122babc27ff22c9cecec049e1fb96464eb006c29741311726b5d12"
  end

  depends_on "imagemagick"

  def install
    cd "src" do
      system "make"
      bin.install "tiv"
    end
  end

  test do
    system bin/"tiv", test_fixtures("test.png")
  end
end
