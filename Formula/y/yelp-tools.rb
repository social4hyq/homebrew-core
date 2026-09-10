class YelpTools < Formula
  include Language::Python::Shebang
  include Language::Python::Virtualenv

  desc "Tools that help create and edit Mallard or DocBook documentation"
  homepage "https://gitlab.gnome.org/GNOME/yelp-tools"
  url "https://download.gnome.org/sources/yelp-tools/42/yelp-tools-42.1.tar.xz"
  sha256 "3e496a4020d4145b99fd508a25fa09336a503a4e8900028421e72c6a4b11f905"
  license "GPL-2.0-or-later"
  revision 4

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "315db2f6bd406b48e3d86cc45441af57071b9560105c0764e8da23276ad314cc"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "itstool"
  depends_on "libxml2"
  depends_on "python@3.14"
  depends_on "yelp-xsl" => :no_linkage

  uses_from_macos "libxslt"

  pypi_packages package_name:   "",
                extra_packages: "lxml"

  resource "lxml" do
    url "https://files.pythonhosted.org/packages/28/30/9abc9e34c657c33834eaf6cd02124c61bdf5944d802aa48e69be8da3585d/lxml-6.1.0.tar.gz"
    sha256 "bfd57d8008c4965709a919c3e9a98f76c2c7cb319086b3d26858250620023b13"
  end

  resource "mallard-rng" do
    url "https://github.com/projectmallard/projectmallard.org/raw/refs/tags/mallard-rng-1.1.0/download/mallard-rng-1.1.0.tar.bz2"
    mirror "https://deb.debian.org/debian/pool/main/m/mallard-rng/mallard-rng_1.1.0.orig.tar.bz2"
    sha256 "66bc8c38758801d5a1330588589b6e81f4d7272a6fbdad0cd4cfcd266848e160"

    livecheck do
      url :url
      regex(/^mallard-rng[._-]v?(\d+(?:\.\d+)+)$/i)
    end
  end

  def install
    resource("mallard-rng").stage do
      system "./configure", "--disable-silent-rules", *std_configure_args(prefix: libexec)
      system "make", "install"
    end

    venv = virtualenv_create(libexec, "python3.14")
    venv.pip_install resources.reject { |r| r.name == "mallard-rng" }
    ENV.prepend_path "PATH", venv.root/"bin"

    system "meson", "setup", "build", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
    rewrite_shebang python_shebang_rewrite_info(venv.root/"bin/python"), *bin.children

    xml_catalog_files = libexec/"etc/xml/mallard/catalog"
    bin.env_script_all_files(libexec/"bin", XML_CATALOG_FILES: "${XML_CATALOG_FILES:-#{xml_catalog_files}}")
  end

  test do
    system bin/"yelp-new", "task", "ducksinarow"
    system bin/"yelp-build", "html", "ducksinarow.page"
    system bin/"yelp-check", "validate", "ducksinarow.page"
  end
end
