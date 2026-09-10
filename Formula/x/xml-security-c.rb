class XmlSecurityC < Formula
  desc "Implementation of primary security standards for XML"
  homepage "https://santuario.apache.org/"
  url "https://shibboleth.net/downloads/xml-security-c/3.0.0/xml-security-c-3.0.0.tar.bz2"
  sha256 "a4c9e1ae3ed3e8dab5d82f4dbdb8414bcbd0199a562ad66cd7c0cd750804ff32"
  license "Apache-2.0"
  revision 1

  livecheck do
    url "https://shibboleth.net/downloads/xml-security-c/"
    regex(%r{href=["']?v?(\d+(?:\.\d+)+)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1bbefa4ad94d06d0211dc903bef682e96a1cf2b8c850aee4047003cb5fca094a"
  end

  depends_on "pkgconf" => :build
  depends_on "openssl@3"
  depends_on "xerces-c"

  # Apply Debian patch to avoid segfault in test
  patch do
    url "https://sources.debian.org/data/main/x/xml-security-c/3.0.0-2/debian/patches/Provide-the-Xerces-URI-Resolver-for-the-tests.patch"
    sha256 "585938480165026990e874fecfae42601dde368f345f1e6ee54b189dbcd01734"
  end

  def install
    system "./configure", "--with-openssl=#{Formula["openssl@3"].opt_prefix}", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match "All tests passed", pipe_output("#{bin}/xsec-xtest 2>&1")
  end
end
