class Cadaver < Formula
  desc "Command-line client for DAV"
  homepage "https://notroj.github.io/cadaver/"
  url "https://notroj.github.io/cadaver/cadaver-0.28.tar.gz"
  sha256 "33e3a54bd54b1eb325b48316a7cacc24047c533ef88e6ef98b88dfbb60e12734"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?cadaver[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "81c8db30c6486787b2e609510f8c2925a1aa9b4920283873fcaba49cab85a789"
  end

  head do
    url "https://github.com/notroj/cadaver.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "gettext" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "neon"
  depends_on "openssl@3"
  depends_on "readline"

  on_macos do
    depends_on "gettext"
  end

  def install
    if build.head?
      ENV["LIBTOOLIZE"] = "glibtoolize"
      system "./autogen.sh"
    end
    system "./configure", "--with-ssl=openssl",
                          "--with-libs=#{Formula["openssl@3"].opt_prefix}",
                          "--with-neon=#{Formula["neon"].opt_prefix}",
                          *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    assert_match "cadaver #{version}", shell_output("#{bin}/cadaver -V", 255)
  end
end
