class SharedMimeInfo < Formula
  desc "Database of common MIME types"
  homepage "https://wiki.freedesktop.org/www/Software/shared-mime-info"
  url "https://ftp.debian.org/debian/pool/main/s/shared-mime-info/shared-mime-info_2.4.orig.tar.bz2"
  sha256 "32dc32ae39ff1c1bf8434dd3b36770b48538a1772bc0298509d034f057005992"
  license "GPL-2.0-only"
  revision 2
  compatibility_version 1
  head "https://gitlab.freedesktop.org/xdg/shared-mime-info.git", branch: "master"

  livecheck do
    url "https://gitlab.freedesktop.org/api/v4/projects/1205/releases"
    regex(/^(?:Release[._-])?v?(\d+(?:[.-]\d+)+)$/i)
    strategy :json do |json, regex|
      json.map { |item| item["tag_name"]&.[](regex, 1)&.tr("-", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8c34e8b62a718123fc8eba6514c7f0ae5029c73d529de80931f58b29cc688b39"
  end

  depends_on "gettext" => :build
  depends_on "itstool" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "xmlto" => :build
  depends_on "glib"

  uses_from_macos "libxml2"

  def install
    ENV["XML_CATALOG_FILES"] = etc/"xml/catalog"

    # Disable the post-install update-mimedb due to crash
    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
    pkgshare.install share/"mime/packages"
    rm_r(share/"mime") if (share/"mime").exist?
  end

  def post_install
    global_mime = HOMEBREW_PREFIX/"share/mime"
    cellar_mime = share/"mime"

    # Remove bad links created by old libheif postinstall
    rm_r(global_mime) if global_mime.symlink?

    rm_r(cellar_mime) if cellar_mime.exist? && !cellar_mime.symlink?
    ln_sf(global_mime, cellar_mime)

    (global_mime/"packages").mkpath
    cp (pkgshare/"packages").children, global_mime/"packages"

    system bin/"update-mime-database", global_mime
  end

  test do
    ENV["XDG_DATA_HOME"] = testpath

    cp_r share/"mime", testpath
    system bin/"update-mime-database", testpath/"mime"
  end
end
