class Unixodbc < Formula
  desc "ODBC 3 connectivity for UNIX"
  homepage "https://www.unixodbc.org/"
  url "https://www.unixodbc.org/unixODBC-2.3.14.tar.gz"
  mirror "https://fossies.org/linux/privat/unixODBC-2.3.14.tar.gz"
  sha256 "4e2814de3e01fc30b0b9f75e83bb5aba91ab0384ee951286504bb70205524771"
  license all_of: [
    "LGPL-2.1-or-later", # libraries
    "GPL-2.0-or-later",  # programs
  ]
  revision 1
  compatibility_version 1

  livecheck do
    url "https://www.unixodbc.org/download.html"
    regex(/href=.*?unixODBC[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4f64607f027b1f34da5d12f8397c9bf432c592d3a592fd2eb57b56ebf40e9eae"
  end

  depends_on "libtool"

  conflicts_with "virtuoso", because: "both install `isql` binaries"

  # These conflict with `libiodbc`, which is now keg-only.
  link_overwrite "include/odbcinst.h", "include/sql.h", "include/sqlext.h",
                 "include/sqltypes.h", "include/sqlucode.h"
  link_overwrite "lib/libodbc.a", "lib/libodbc.so"

  def install
    system "./configure", "--disable-gui",
                          "--enable-static",
                          "--sysconfdir=#{etc}",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"odbcinst", "-j"
  end
end
