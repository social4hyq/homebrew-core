class Psqlodbc < Formula
  desc "Official PostgreSQL ODBC driver"
  homepage "https://odbc.postgresql.org"
  url "https://github.com/postgresql-interfaces/psqlodbc/archive/refs/tags/REL-18_00_0001.tar.gz"
  sha256 "2cf6f19d72765f0b8c2a8a9f4000f1ae1835e737c4899dc931dd6d7a7a0c87dc"
  license "LGPL-2.0-or-later"
  head "https://github.com/postgresql-interfaces/psqlodbc.git", branch: "main"

  livecheck do
    url :stable
    regex(/^REL[._-]?v?(\d+(?:[._]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7896b57286ea578743bec353daf7a664d6a2de54be040c4a3e6a2e1e4dd105f7"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "libpq"
  depends_on "unixodbc"

  def install
    system "./bootstrap"
    system "./configure", "--prefix=#{prefix}",
                          "--with-unixodbc=#{Formula["unixodbc"].opt_prefix}"
    system "make"
    system "make", "install"
  end

  test do
    output = shell_output("#{Formula["unixodbc"].bin}/dltest #{lib}/psqlodbcw.so")
    assert_equal "SUCCESS: Loaded #{lib}/psqlodbcw.so\n", output
  end
end
