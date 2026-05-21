class RedisLeveldb < Formula
  desc "Redis-protocol compatible frontend to leveldb"
  homepage "https://github.com/KDr2/redis-leveldb"
  url "https://github.com/KDr2/redis-leveldb/archive/refs/tags/v1.4.tar.gz"
  sha256 "b34365ca5b788c47b116ea8f86a7a409b765440361b6c21a46161a66f631797c"
  license "MIT"
  revision 4
  head "https://github.com/KDr2/redis-leveldb.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "23e60e223690e843035f36fd29f4efd8624d9cfc6fa678e7a3a2f492d8cbf0ba"
  end

  depends_on "gmp"
  depends_on "leveldb"
  depends_on "libev"
  depends_on "snappy"

  def install
    inreplace "src/Makefile", "../vendor/libleveldb.a", Formula["leveldb"].opt_lib/"libleveldb.a"
    ENV.prepend "LDFLAGS", "-lsnappy"
    system "make"
    bin.install "redis-leveldb"
  end

  test do
    system bin/"redis-leveldb", "-h"
  end
end
