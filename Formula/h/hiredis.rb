class Hiredis < Formula
  desc "Minimalistic client for Redis"
  homepage "https://github.com/redis/hiredis"
  url "https://github.com/redis/hiredis/archive/refs/tags/v1.4.0.tar.gz"
  sha256 "5fa6e719e59cd4f8ae435c52a18ac4035d135251f9ee54e7a045bccf59107ed8"
  license "BSD-3-Clause"
  compatibility_version 1
  head "https://github.com/redis/hiredis.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a6c10240c08f80917ee295076b64a14c9f360cdbe615ba104d68ca1367ce2082"
  end

  depends_on "openssl@3"

  def install
    system "make", "install", "PREFIX=#{prefix}", "USE_SSL=1"
    pkgshare.install "examples"
  end

  test do
    # running `./test` requires a database to connect to, so just make
    # sure it compiles
    system ENV.cc, pkgshare/"examples/example.c", "-o", testpath/"test",
                   "-I#{include}/hiredis", "-L#{lib}", "-lhiredis"
    assert_path_exists testpath/"test"
  end
end
