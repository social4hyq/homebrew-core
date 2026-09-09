class Lmdb < Formula
  desc "Lightning memory-mapped database: key-value data store"
  homepage "https://www.symas.com/symas-embedded-database-lmdb"
  url "https://git.openldap.org/openldap/openldap/-/archive/LMDB_1.0.2/openldap-LMDB_1.0.2.tar.bz2"
  sha256 "f35a2eb3a8e51650397604bbb49a1295221cd4739ff787d324f6c442c138a3ee"
  license "OLDAP-2.8"
  version_scheme 1
  compatibility_version 1
  head "https://git.openldap.org/openldap/openldap.git", branch: "mdb.master"

  livecheck do
    url :stable
    regex(/^LMDB[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "59e3929fc4ff5779f7ca75a154e34c3f4006f9433579099830bb4c21bbdd015c"
  end

  depends_on "pkgconf" => :test

  def install
    ENV.append "CPPFLAGS", "-DMDB_USE_ROBUST=0"

    cd "libraries/liblmdb" do
      args = []
      args << "SOEXT=.dylib" if OS.mac?
      system "make", *args
      system "make", "install", *args, "prefix=#{prefix}"
    end

    (lib/"pkgconfig/lmdb.pc").write pc_file
    (lib/"pkgconfig").install_symlink "lmdb.pc" => "liblmdb.pc"
  end

  def pc_file
    <<~EOS
      prefix=#{opt_prefix}
      exec_prefix=${prefix}
      libdir=${prefix}/lib
      includedir=${prefix}/include

      Name: lmdb
      Description: #{desc}
      URL: #{homepage}
      Version: #{version}
      Libs: -L${libdir} -llmdb
      Cflags: -I${includedir}
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mdb_dump -V")

    # Make sure our `lmdb.pc` can be read by `pkg-config`.
    system "pkg-config", "lmdb"
  end
end
