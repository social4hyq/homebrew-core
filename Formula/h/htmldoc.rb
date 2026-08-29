class Htmldoc < Formula
  desc "Convert HTML to PDF or PostScript"
  homepage "https://www.msweet.org/htmldoc/"
  url "https://github.com/michaelrsweet/htmldoc/archive/refs/tags/v1.9.24.tar.gz"
  sha256 "2054791d013e0b9c356dddfeddc5ca920d25b3d97a7366f28e03ec0fd6684970"
  license "GPL-2.0-only"
  head "https://github.com/michaelrsweet/htmldoc.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c7e2610f270ed2bc841a171ea39e541de97153d76a713bac23fd42367cca1747"
  end

  depends_on "pkgconf" => :build
  depends_on "jpeg-turbo"
  depends_on "libpng"

  uses_from_macos "cups"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "./configure", "--without-gui", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    system bin/"htmldoc", "--version"
  end
end
