class Libidn < Formula
  desc "International domain name library"
  homepage "https://www.gnu.org/software/libidn/"
  url "https://ftpmirror.gnu.org/gnu/libidn/libidn-1.44.tar.gz"
  mirror "https://ftp.gnu.org/gnu/libidn/libidn-1.44.tar.gz"
  sha256 "499608bab3a65650a0ea52888c13a8deebe3f71408e319acd9ec52e02eb13959"
  license any_of: ["GPL-2.0-or-later", "LGPL-3.0-or-later"]
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6294e69813532432800a611c7a9b7dee13de5154e6ea6b7dd203dbf06474889d"
  end

  depends_on "pkgconf" => :build

  def install
    system "./configure", "--disable-csharp",
                          "--with-lispdir=#{elisp}",
                          *std_configure_args
    system "make", "install"
  end

  test do
    ENV["CHARSET"] = "UTF-8"
    system bin/"idn", "räksmörgås.se", "blåbærgrød.no"
  end
end
