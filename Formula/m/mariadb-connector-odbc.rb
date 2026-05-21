class MariadbConnectorOdbc < Formula
  desc "Database driver using the industry standard ODBC API"
  homepage "https://mariadb.org/download/?tab=connector&prod=connector-odbc"
  url "https://archive.mariadb.org/connector-odbc-3.2.8/mariadb-connector-odbc-3.2.8-src.tar.gz"
  mirror "https://fossies.org/linux/misc/mariadb-connector-odbc-3.2.8-src.tar.gz/"
  sha256 "9968979aae46a1750452eb934558af81c6eda957eaee00f7ec72b24ee8ead547"
  license "LGPL-2.1-or-later"

  livecheck do
    url "https://downloads.mariadb.org/rest-api/connector-odbc/all-releases/?olderReleases=false"
    strategy :json do |json|
      json["releases"]&.map do |release|
        next if release["status"] != "stable"

        release["release_number"]
      end
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "84b58d2945d071a27addbe9648d550e12e003b162a37b4877478f1d593fabc1e"
  end

  depends_on "cmake" => :build
  depends_on "mariadb-connector-c"
  depends_on "openssl@3"
  depends_on "unixodbc"

  def install
    ENV.append_to_cflags "-I#{Formula["mariadb-connector-c"].opt_include}/mariadb"
    ENV.append "LDFLAGS", "-L#{Formula["mariadb-connector-c"].opt_lib}/mariadb"
    ENV.append "LDFLAGS", "-Wl,-rpath,#{Formula["mariadb-connector-c"].opt_lib}/mariadb" if OS.linux?
    args = [
      "-DMARIADB_LINK_DYNAMIC=1",
      "-DWITH_SSL=OPENSSL",
      "-DOPENSSL_ROOT_DIR=#{Formula["openssl@3"].opt_prefix}",
      "-DWITH_IODBC=0",
      "-DICONV_INCLUDE_DIR=/usr/include",
    ]

    if OS.mac?
      # Workaround 3.1.11 issues finding system's built-in -liconv
      # See https://jira.mariadb.org/browse/ODBC-299
      args << "-DICONV_LIBRARIES=#{MacOS.sdk_path}/usr/lib/libiconv.tbd"
    end

    system "cmake", ".", *args, *std_cmake_args

    # By default, the installer pkg is built - we don't want that.
    # maodbc limits the build to just the connector itself.
    # install/fast prevents an "all" build being invoked that a regular "install" would do.
    system "make", "maodbc"
    system "make", "install/fast"
  end

  test do
    output = shell_output("#{Formula["unixodbc"].opt_bin}/dltest #{lib}/mariadb/#{shared_library("libmaodbc")}")
    assert_equal "SUCCESS: Loaded #{lib}/mariadb/#{shared_library("libmaodbc")}", output.chomp
  end
end
