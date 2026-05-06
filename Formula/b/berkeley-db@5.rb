class BerkeleyDbAT5 < Formula
  desc "High performance key/value database"
  homepage "https://www.oracle.com/database/technologies/related/berkeleydb.html"
  url "https://download.oracle.com/berkeley-db/db-5.3.28.tar.gz"
  sha256 "e0a992d740709892e81f9d93f06daf305cf73fb81b545afe72478043172c3628"
  license "Sleepycat"
  revision 1

  livecheck do
    skip "No longer developed or maintained"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "35970c5b29242eb6b6dee25ca0b746b43c848b78e7af4881c478653078807c06"
  end

  keg_only :versioned_formula

  # Fix build with recent clang
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/berkeley-db@4/clang.diff"
    sha256 "86111b0965762f2c2611b302e4a95ac8df46ad24925bbb95a1961542a1542e40"
    directory "src"
  end

  # Further fixes for clang
  patch :p0 do
    url "https://raw.githubusercontent.com/NetBSD/pkgsrc/6034096dc85159a02116524692545cf5752c8f33/databases/db5/patches/patch-src_dbinc_db.in"
    sha256 "302b78f3e1f131cfbf91b24e53a5c79e1d9234c143443ab936b9e5ad08dea5b6"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-pre-0.4.2.418-big_sur.diff"
    sha256 "83af02f2aa2b746bb7225872cab29a253264be49db0ecebb12f841562d9a2923"
    directory "dist"
  end

  def install
    # BerkeleyDB dislikes parallel builds
    ENV.deparallelize

    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1200

    args = %W[
      --disable-static
      --prefix=#{prefix}
      --mandir=#{man}
      --enable-cxx
      --enable-dbm
    ]
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm64?

    # BerkeleyDB requires you to build everything from the build_unix subdirectory
    cd "build_unix" do
      system "../dist/configure", *args
      system "make", "install"

      # use the standard docs location
      doc.parent.mkpath
      mv prefix/"docs", doc
    end
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <assert.h>
      #include <string.h>
      #include <db_cxx.h>
      int main() {
        Db db(NULL, 0);
        assert(db.open(NULL, "test.db", NULL, DB_BTREE, DB_CREATE, 0) == 0);

        const char *project = "Homebrew";
        const char *stored_description = "The missing package manager for macOS";
        Dbt key(const_cast<char *>(project), strlen(project) + 1);
        Dbt stored_data(const_cast<char *>(stored_description), strlen(stored_description) + 1);
        assert(db.put(NULL, &key, &stored_data, DB_NOOVERWRITE) == 0);

        Dbt returned_data;
        assert(db.get(NULL, &key, &returned_data, 0) == 0);
        assert(strcmp(stored_description, (const char *)(returned_data.get_data())) == 0);

        assert(db.close(0) == 0);
      }
    CPP
    flags = %W[
      -I#{include}
      -L#{lib}
      -ldb_cxx
    ]
    system ENV.cxx, "test.cpp", "-o", "test", *flags
    system "./test"
    assert_path_exists testpath/"test.db"
  end
end
