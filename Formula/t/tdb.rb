class Tdb < Formula
  desc "Trivial DataBase, by the Samba project"
  homepage "https://tdb.samba.org/"
  url "https://www.samba.org/ftp/tdb/tdb-1.4.15.tar.gz"
  sha256 "fba09d8df1f1b9072aeae8e78b2bd43c5afef20b2f6deefa633aa14a377a8dd2"
  license all_of: [
    "LGPL-3.0-or-later",
    "GPL-3.0-or-later", # tools/
  ]

  livecheck do
    url "https://www.samba.org/ftp/tdb/"
    regex(/href=.*?tdb[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8f8734c9b988678bbd71f5e06b7e0fda140085e2d0bed221d2118aba6da6a453"
  end

  uses_from_macos "python" => :build

  conflicts_with "jena", because: "both install `tdbbackup`, `tdbdump` binaries"

  def install
    system "./configure", "--bundled-libraries=NONE",
                          "--disable-python",
                          "--disable-rpath",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    testdb = "test-db.tdb"

    # database creation
    pipe_output("#{bin}/tdbtool", "create #{testdb}\ninsert foo bar\n", 0)
    assert_path_exists testpath/testdb
    assert_match "Database integrity is OK and has 1 records.", pipe_output("#{bin}/tdbtool #{testdb}", "check\n")
    assert_match "key 3 bytes: foo", pipe_output("#{bin}/tdbtool #{testdb}", "keys\n")
  end
end
