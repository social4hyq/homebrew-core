class Libidn < Formula
  desc "International domain name library"
  homepage "https://www.gnu.org/software/libidn/"
  url "https://ftpmirror.gnu.org/gnu/libidn/libidn-1.43.tar.gz"
  mirror "https://ftp.gnu.org/gnu/libidn/libidn-1.43.tar.gz"
  sha256 "bdc662c12d041b2539d0e638f3a6e741130cdb33a644ef3496963a443482d164"
  license any_of: ["GPL-2.0-or-later", "LGPL-3.0-or-later"]
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c86450199fedc06c2c587ddeabb836ebeb18c4788993b9e2e9b007de16e0f904"
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
