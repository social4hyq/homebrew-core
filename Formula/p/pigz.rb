class Pigz < Formula
  desc "Parallel gzip"
  homepage "https://zlib.net/pigz/"
  url "https://zlib.net/pigz/pigz-2.8.tar.gz"
  sha256 "eb872b4f0e1f0ebe59c9f7bd8c506c4204893ba6a8492de31df416f0d5170fd0"
  license "Zlib"
  revision 1
  head "https://github.com/madler/pigz.git", branch: "master"

  livecheck do
    url :homepage
    regex(/href=.*?pigz[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c85c25fc9c8af051e194238b2d00cb67b17eb5b80002e41d4bf55a5143160180"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "make", "CC=#{ENV.cc}", "CFLAGS=#{ENV.cflags}"
    bin.install "pigz", "unpigz"
    man1.install "pigz.1"
    man1.install_symlink "pigz.1" => "unpigz.1"
  end

  test do
    test_data = "a" * 1000
    (testpath/"example").write test_data
    system bin/"pigz", testpath/"example"
    assert_predicate testpath/"example.gz", :file?
    system bin/"unpigz", testpath/"example.gz"
    assert_equal test_data, (testpath/"example").read
    system "/bin/dd", "if=/dev/random", "of=foo.bin", "bs=1024k", "count=10"
    system bin/"pigz", "foo.bin"
  end
end
