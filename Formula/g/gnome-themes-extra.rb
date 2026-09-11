class GnomeThemesExtra < Formula
  desc "Extra themes for the GNOME desktop environment"
  homepage "https://gitlab.gnome.org/Archive/gnome-themes-extra"
  url "https://download.gnome.org/sources/gnome-themes-extra/3.28/gnome-themes-extra-3.28.tar.xz"
  sha256 "7c4ba0bff001f06d8983cfc105adaac42df1d1267a2591798a780bac557a5819"
  license "LGPL-2.1-or-later"
  revision 2

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2d8ce8dbc04d30e36ac0999c124443f5927d24d9827de7c51a72a74a8c4c6c6f"
  end

  deprecate! date: "2024-12-10", because: :repo_archived
  disable! date: "2025-12-10", because: :repo_archived

  depends_on "gettext" => :build
  depends_on "intltool" => :build
  depends_on "pkgconf" => :build

  depends_on "cairo"
  depends_on "glib"
  depends_on "gtk+"

  uses_from_macos "perl" => :build

  on_macos do
    depends_on "at-spi2-core"
    depends_on "gdk-pixbuf"
    depends_on "gettext"
    depends_on "harfbuzz"
    depends_on "pango"
  end

  on_linux do
    depends_on "perl-xml-parser" => :build
  end

  def install
    # To find gtk-update-icon-cache
    ENV.prepend_path "PATH", Formula["gtk+"].opt_libexec
    system "./configure", "--disable-gtk3-engine",
                          "--disable-silent-rules",
                          *std_configure_args
    system "make", "install"
  end

  test do
    assert_path_exists share/"icons/HighContrast/scalable/actions/document-open-recent.svg"
    assert_path_exists lib/"gtk-2.0/2.10.0/engines/libadwaita.so"
  end
end
