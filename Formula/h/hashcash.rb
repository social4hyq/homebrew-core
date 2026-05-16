class Hashcash < Formula
  desc "Proof-of-work algorithm to counter denial-of-service (DoS) attacks"
  homepage "http://hashcash.org"
  url "https://deb.debian.org/debian/pool/main/h/hashcash/hashcash_1.22.orig.tar.gz"
  mirror "http://hashcash.org/source/hashcash-1.22.tgz"
  sha256 "0192f12d41ce4848e60384398c5ff83579b55710601c7bffe6c88bc56b547896"
  license any_of: [:public_domain, "BSD-3-Clause", "LGPL-2.1-only", "GPL-2.0-only"]
  revision 2

  livecheck do
    url "http://hashcash.org/source/"
    regex(/href=.*?hashcash[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c994f23f823717f9aab02becbfb4ccbc41385fc4394d2da55ad65827c653665f"
  end

  depends_on "openssl@4"

  def install
    ENV.append_to_cflags "-Dunix"
    platform = Hardware::CPU.intel? ? "x86" : "generic"
    system "make", "#{platform}-openssl",
                   "LIBCRYPTO=#{Formula["openssl@4"].opt_lib}/#{shared_library("libcrypto")}"
    system "make", "install",
                   "PACKAGER=HOMEBREW",
                   "INSTALL_PATH=#{bin}",
                   "MAN_INSTALL_PATH=#{man1}",
                   "DOC_INSTALL_PATH=#{doc}"
  end

  test do
    system bin/"hashcash", "-mb10", "test@example.com"
  end
end
