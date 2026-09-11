class YelpXsl < Formula
  desc "Document transformations from Yelp"
  homepage "https://gitlab.gnome.org/GNOME/yelp-xsl"
  url "https://download.gnome.org/sources/yelp-xsl/49/yelp-xsl-49.0.tar.xz"
  sha256 "59d43a8f8fe67b784f14f9a04dd4a7a092a7f4a64a65e71b90fe02a47a50fbec"
  license all_of: ["GPL-2.0-or-later", "LGPL-2.1-or-later", "MIT", "BSD-3-Clause"]
  revision 1
  head "https://gitlab.gnome.org/GNOME/yelp-xsl.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a3e809fb7a9b979516b38e845de033dc2324d131e967b892e66e2a0afec81f11"
  end

  depends_on "gettext" => :build
  depends_on "itstool" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build

  uses_from_macos "libxslt" => [:build, :test]

  def install
    inreplace "yelp-xsl.pc.in", "@prefix@", opt_prefix

    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
    (pkgshare/"test").install "test/colors/testcolors.xsl"
  end

  test do
    cp pkgshare/"test/testcolors.xsl", testpath
    inreplace "testcolors.xsl", "\"../../xslt/common/", "\"#{pkgshare}/xslt/common/"
    system "xsltproc", "-o", "testcolors.html", "testcolors.xsl", "testcolors.xsl"
    assert_match "rgb(173,25,36) red 6.54", File.read("testcolors.html")
  end
end
