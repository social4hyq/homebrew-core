class MmCommon < Formula
  desc "Build utilities for C++ interfaces of GTK+ and GNOME packages"
  homepage "https://www.gtkmm.org/"
  url "https://download.gnome.org/sources/mm-common/1.0/mm-common-1.0.8.tar.xz"
  sha256 "b189ee636e839d12c00dabefae099fd488ab2358dec24d264761c011950b02a9"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c00a26d3e7579e6e8f7004631183c480070be51d21b22f5f9b6450be86183a6e"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "python@3.14"

  def install
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    mkdir testpath/"test"
    touch testpath/"test/a"

    system bin/"mm-common-prepare", "-c", testpath/"test/a"
    assert_path_exists testpath/"test/compile-binding.am"
    assert_path_exists testpath/"test/dist-changelog.am"
    assert_path_exists testpath/"test/doc-reference.am"
    assert_path_exists testpath/"test/generate-binding.am"
  end
end
