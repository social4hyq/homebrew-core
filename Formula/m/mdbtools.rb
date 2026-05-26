class Mdbtools < Formula
  desc "Tools to facilitate the use of Microsoft Access databases"
  homepage "https://github.com/mdbtools/mdbtools/"
  url "https://github.com/mdbtools/mdbtools/releases/download/v1.0.1/mdbtools-1.0.1.tar.gz"
  sha256 "ff9c425a88bc20bf9318a332eec50b17e77896eef65a0e69415ccb4e396d1812"
  license "GPL-2.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "daab94a9c018b067302ce1175495d20b3db04283262a67f853e226ef6e5f1de7"
  end

  depends_on "bison" => :build
  depends_on "gawk" => :build
  depends_on "pkgconf" => :build

  depends_on "glib"
  depends_on "readline"
  depends_on "unixodbc"

  uses_from_macos "flex" => :build

  on_macos do
    depends_on "gettext"
  end

  def install
    system "./configure", "--enable-man",
                          "--with-unixodbc=#{Formula["unixodbc"].opt_prefix}",
                          *std_configure_args
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/mdb-schema --drop-table test 2>&1", 1)

    expected_output = <<~EOS
      File not found
      Could not open file
    EOS
    assert_match expected_output, output
  end
end
