class Xapian < Formula
  desc "C++ search engine library"
  homepage "https://xapian.org/"
  url "https://oligarchy.co.uk/xapian/2.0.0/xapian-core-2.0.0.tar.xz"
  sha256 "6cea3f49952a47224439a40bdb3608f928d121ad8721b9921cc42802d548ecf8"
  license "GPL-2.0-or-later"
  version_scheme 1
  compatibility_version 1

  livecheck do
    url "https://xapian.org/download"
    regex(/href=.*?xapian-core[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f1ae371e029a2edaa9022c551b850ed22e59565c575bbae9c2fd7ba31cd77729"
  end

  depends_on "python@3.14" => [:build, :test]
  depends_on "sphinx-doc" => :build

  on_linux do
    depends_on "util-linux"
    depends_on "zlib-ng-compat"
  end

  skip_clean :la

  resource "bindings" do
    url "https://oligarchy.co.uk/xapian/2.0.0/xapian-bindings-2.0.0.tar.xz"
    sha256 "9a544b69c31355a92edbcd4102cf0f1ec4407fd0a4645f4870fb52300b736910"

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
