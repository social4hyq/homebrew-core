class Libiodbc < Formula
  desc "Database connectivity layer based on ODBC. (alternative to unixodbc)"
  homepage "https://www.iodbc.org/"
  url "https://github.com/openlink/iODBC/archive/refs/tags/v3.52.16.tar.gz"
  sha256 "a0cf0375b462f98c0081c2ceae5ef78276003e57cdf1eb86bd04508fb62a0660"
  license any_of: ["BSD-3-Clause", "LGPL-2.0-only"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1e19ef02618e8f469b8d9cd40cc49b95a74ed075c1b1edd345b8ee4641a040d4"
  end

  keg_only "it conflicts with `unixodbc`"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    system "./autogen.sh"
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"iodbc-config", "--version"
  end
end
