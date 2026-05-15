class HttpLoad < Formula
  desc "Test throughput of a web server by running parallel fetches"
  homepage "https://www.acme.com/software/http_load/"
  url "https://www.acme.com/software/http_load/http_load-09Mar2016.tar.gz"
  version "20160309"
  sha256 "5a7b00688680e3fca8726dc836fd3f94f403fde831c71d73d9a1537f215b4587"
  license "BSD-2-Clause"
  revision 2

  livecheck do
    url :homepage
    regex(/href=.*?http_load[._-]v?(\d+[a-z]+\d+)\.t/i)
    strategy :page_match do |page, regex|
      # Convert date-based version from 09Mar2016 format to 20160309
      page.scan(regex).map do |match|
        date_str = match&.first
        date_str ? Date.parse(date_str)&.strftime("%Y%m%d") : nil
      end
    end
  end

  no_autobump! because: :incompatible_version_format

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "db4d791e1dce2eef0f8b7d8e746a9dafe51df1f85bac78c193f01d3d624b10e7"
  end

  # Upstream repo url is only available via http.
  disable! date: "2026-07-24", because: :repo_removed

  depends_on "openssl@3"

  def install
    bin.mkpath
    man1.mkpath

    args = %W[
      BINDIR=#{bin}
      LIBDIR=#{lib}
      MANDIR=#{man1}
      CC=#{ENV.cc}
      SSL_TREE=#{Formula["openssl@3"].opt_prefix}
    ]

    inreplace "Makefile", "#SSL_", "SSL_"
    system "make", "install", *args
  end

  test do
    (testpath/"urls").write "https://brew.sh/"
    system bin/"http_load", "-rate", "1", "-fetches", "1", "urls"
  end
end
