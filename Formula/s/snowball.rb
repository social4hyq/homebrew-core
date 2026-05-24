class Snowball < Formula
  desc "Stemming algorithms"
  homepage "https://snowballstem.org"
  url "https://github.com/snowballstem/snowball/archive/refs/tags/v3.1.0.tar.gz"
  sha256 "e49fa0a641be9b93d6b4040785007e82d7b5c74eaca51a6d40e47b516a528927"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b13875e8ae7d65bc8d2daed90bcd77ae01d97763823aca511792e26cae841acc"
  end

  def install
    system "make"

    lib.install "libstemmer.a"
    include.install Dir["include/*"]
    pkgshare.install "examples"
  end

  test do
    (testpath/"test.txt").write("connection")
    cp pkgshare/"examples/stemwords.c", testpath
    system ENV.cc, "stemwords.c", "-L#{lib}", "-lstemmer", "-o", "test"
    assert_equal "connect\n", shell_output("./test -i test.txt")
  end
end
