class Dbxml < Formula
  desc "Embeddable XML database with XQuery support and other advanced features"
  homepage "https://www.oracle.com/database/technologies/related/berkeleydb.html"
  url "https://download.oracle.com/berkeley-db/dbxml-6.1.4.tar.gz"
  sha256 "a8fc8f5e0c3b6e42741fa4dfc3b878c982ff8f5e5f14843f6a7e20d22e64251a"
  license "AGPL-3.0-only"
  revision 4

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cc193a13216b187971f83b51d4b52ec98c87d235c63b677f5c5f966c418b8ed1"
  end

  deprecate! date: "2026-04-18", because: :unmaintained
  disable! date: "2027-04-18", because: :unmaintained

  depends_on "berkeley-db"
  depends_on "xerces-c"
  depends_on "xqilla"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # No public bug tracker or mailing list to submit this to, unfortunately.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/2c3abc44ccac26dc8ecf09a8fb6cf33f47b5cfc9/Patches/dbxml/cxx11.patch"
    sha256 "98d518934072d86c15780f10ceee493ca34bba5bc788fd9db1981a78234b0dc4"
  end

  def install
    ENV.cxx11

    inreplace "dbxml/configure" do |s|
      s.gsub! %r{=`ls ("\$with_berkeleydb"/lib)/libdb-\*\.la \| sed -e 's/\.\*db-\\\(\.\*\\\)\.la/},
              "=`find \\1 -name #{shared_library("libdb-*")} -maxdepth 1 ! -type l " \
              "| sed -e 's/#{shared_library(".*db-\\(.*\\)")}/"
      s.gsub! "lib/libdb-*.la", "lib/#{shared_library("libdb-*")}"
      s.gsub! "libz.a", shared_library("libz")
    end

    args = %W[
      --with-xqilla=#{Formula["xqilla"].opt_prefix}
      --with-xerces=#{Formula["xerces-c"].opt_prefix}
      --with-berkeleydb=#{Formula["berkeley-db"].opt_prefix}
    ]
    args << "--with-zlib=#{Formula["zlib-ng-compat"].opt_prefix}" unless OS.mac?
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm64?

    cd "dbxml" do
      system "./configure", *std_configure_args, *args
      system "make", "install"
    end
  end

  test do
    (testpath/"simple.xml").write <<~XML
      <breakfast_menu>
        <food>
          <name>Belgian Waffles</name>
          <calories>650</calories>
        </food>
        <food>
          <name>Homestyle Breakfast</name>
          <calories>950</calories>
        </food>
      </breakfast_menu>
    XML

    (testpath/"dbxml.script").write <<~EOS
      createContainer ""
      putDocument simple "simple.xml" f
      cquery 'sum(//food/calories)'
      print
      quit
    EOS
    assert_equal "1600", shell_output("#{bin}/dbxml -s #{testpath}/dbxml.script").chomp
  end
end
