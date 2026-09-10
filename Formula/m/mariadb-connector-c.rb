class MariadbConnectorC < Formula
  desc "MariaDB database connector for C applications"
  homepage "https://mariadb.org/download/?tab=connector&prod=connector-c"
  # TODO: Remove backward compatibility library symlinks on breaking version bump
  url "https://archive.mariadb.org/connector-c-3.4.9/mariadb-connector-c-3.4.9-src.tar.gz"
  mirror "https://fossies.org/linux/misc/mariadb-connector-c-3.4.9-src.tar.gz/"
  sha256 "a84bba97e59b6a322637a189964d4fd72bd8d92f2d22a9f8d6a5f0657c821e97"
  license "LGPL-2.1-or-later"
  revision 1
  compatibility_version 1
  head "https://github.com/mariadb-corporation/mariadb-connector-c.git", branch: "3.4"

  # The REST API may omit the newest major/minor versions unless the
  # `olderReleases` parameter is set to `true`.
  livecheck do
    url "https://downloads.mariadb.org/rest-api/connector-c/all-releases/?olderReleases=true"
    strategy :json do |json|
      json["releases"]&.map do |_, group|
        group["children"]&.map do |release|
          next if release["status"] != "stable"

          release["release_number"]
        end
      end&.flatten
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "46ca4a3baf66fd75a5e40171e8389c42ba5fe9f2736acb15696ecf6158a76d80"
  end

  keg_only "it conflicts with mariadb"

  depends_on "cmake" => :build
  depends_on "openssl@3"
  depends_on "zstd"

  uses_from_macos "curl"
  uses_from_macos "krb5"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    rm_r "external"

    # -DINSTALL_* are relative to prefix
    args = %w[
      -DINSTALL_LIBDIR=lib
      -DINSTALL_MANDIR=share/man
      -DWITH_EXTERNAL_ZLIB=ON
      -DWITH_MYSQLCOMPAT=ON
      -DWITH_UNIT_TESTS=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # Add mysql_config symlink for compatibility which simplifies building
    # some dependents. This is done in the full `mariadb` installation[^1]
    # but not in the standalone `mariadb-connector-c`.
    #
    # [^1]: https://github.com/MariaDB/server/blob/main/cmake/symlinks.cmake
    bin.install_symlink "mariadb_config" => "mysql_config"

    # Temporary symlinks for backwards compatibility.
    # TODO: Remove in future version update.
    (lib/"mariadb").install_symlink lib.glob(shared_library("*"))

    # TODO: Automatically compress manpages in brew
    Utils::Gzip.compress(*man3.glob("*.3"))
  end

  test do
    system bin/"mariadb_config", "--cflags"
  end
end
