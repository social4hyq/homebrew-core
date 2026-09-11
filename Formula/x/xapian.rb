class Xapian < Formula
  desc "C++ search engine library"
  homepage "https://xapian.org/"
  url "https://oligarchy.co.uk/xapian/2.1.0/xapian-core-2.1.0.tar.xz"
  sha256 "8e1259586d342e3d12b5e1f772e9185a10f2ba16e541566b5c3c239f71b8aacc"
  license "GPL-2.0-or-later"
  revision 1
  version_scheme 1
  compatibility_version 1

  livecheck do
    url "https://xapian.org/download"
    regex(/href=.*?xapian-core[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "93be8522920b85a813df26bb582f39512e543dcfd35ae31cbf8df1c2980c16d1"
  end

  depends_on "python@3.14" => [:build, :test]
  depends_on "sphinx-doc" => :build

  on_linux do
    depends_on "util-linux"
    depends_on "zlib-ng-compat"
  end

  skip_clean :la

  resource "bindings" do
    url "https://oligarchy.co.uk/xapian/2.1.0/xapian-bindings-2.1.0.tar.xz"
    sha256 "f52ec189f13b4fa66ea625a6eb94bb32dd651b9ec806be6a911dda54cbe3875c"

    livecheck do
      formula :parent
    end
  end

  def python3
    "python3.14"
  end

  def install
    odie "bindings resource needs to be updated" if version != resource("bindings").version

    ENV["PYTHON"] = which(python3)
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make", "install"

    resource("bindings").stage do
      ENV["XAPIAN_CONFIG"] = bin/"xapian-config"
      ENV.delete "PYTHONDONTWRITEBYTECODE" # makefile relies on install .pyc files

      site_packages = Language::Python.site_packages(python3)
      ENV.prepend_create_path "PYTHON3_LIB", prefix/site_packages

      ENV.append_path "PYTHONPATH", Formula["sphinx-doc"].opt_libexec/site_packages
      ENV.append_path "PYTHONPATH", Formula["sphinx-doc"].opt_libexec/"vendor"/site_packages

      system "./configure", *std_configure_args, "--disable-silent-rules", "--with-python3"
      system "make", "install"
    end
  end

  test do
    system bin/"xapian-config", "--libs"
    system python3, "-c", "import xapian"
  end
end
