class Libmaxminddb < Formula
  desc "C library for the MaxMind DB file format"
  homepage "https://github.com/maxmind/libmaxminddb"
  url "https://github.com/maxmind/libmaxminddb/releases/download/1.13.3/libmaxminddb-1.13.3.tar.gz"
  sha256 "a66502ea76eadbe17f2cd6fd708946777253972d2ae8157dee1b23a2fb528171"
  license "Apache-2.0"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "157792636ec41bbef563cc8ac34972999185a870f68d1edaf3b288058e30686c"
  end

  head do
    url "https://github.com/maxmind/libmaxminddb.git", branch: "main"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  def install
    system "./bootstrap" if build.head?

    # OHOS musl open_memstream bug: fclose fails to flush, leaving buf/sz
    # unset. Explicit fflush before fclose works around this.
    inreplace "t/dump_t.c",
              "fclose(stream);",
              "fflush(stream);\n    fclose(stream);"

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "check"
    system "make", "install"
    (share/"examples").install buildpath/"t/maxmind-db/test-data/GeoIP2-City-Test.mmdb"
  end

  test do
    system bin/"mmdblookup", "-f", "#{share}/examples/GeoIP2-City-Test.mmdb",
                                "-i", "175.16.199.0"
  end
end
