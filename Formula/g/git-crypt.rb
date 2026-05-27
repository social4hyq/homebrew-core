class GitCrypt < Formula
  desc "Enable transparent encryption/decryption of files in a git repo"
  homepage "https://www.agwa.name/projects/git-crypt/"
  url "https://www.agwa.name/projects/git-crypt/downloads/git-crypt-0.8.0.tar.gz"
  sha256 "540d424f87bed7994a4551a8c24b16e50d3248a5b7c3fd8ceffe94bfd4af0ad9"
  license "GPL-3.0-or-later"
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?git-crypt[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8dd4bff31cbfd1526203848dc2fa96e73ff38c7ca59a69770b673c9176b0b059"
  end

  depends_on "docbook" => :build
  depends_on "docbook-xsl" => :build
  depends_on "openssl@4"

  uses_from_macos "libxslt" => :build

  def install
    # fix docbook load issue
    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    system "make", "ENABLE_MAN=yes", "PREFIX=#{prefix}", "install"
  end

  test do
    system bin/"git-crypt", "keygen", "keyfile"
  end
end
