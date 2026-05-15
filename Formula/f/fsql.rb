class Fsql < Formula
  desc "Search through your filesystem with SQL-esque queries"
  homepage "https://github.com/kashav/fsql"
  url "https://github.com/kashav/fsql/archive/refs/tags/v0.5.2.tar.gz"
  sha256 "21f12261516bfa2ebc4136b7e7e08a23743809e847dfdace3c1f6ac88023277d"
  license "MIT"
  head "https://github.com/kashav/fsql.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5c79975bc1496b1fbe6d3613be35eb5b1ed1e15d7426d917b6db92625dd012f8"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/fsql"
  end

  test do
    (testpath/"bar.txt").write("hello")
    (testpath/"foo/baz.txt").write("world")
    cmd = "#{bin}/fsql SELECT FULLPATH\\(name\\) FROM foo"
    assert_match %r{^foo\s+foo/baz.txt$}, shell_output(cmd)
    cmd = "#{bin}/fsql SELECT name FROM . WHERE name = bar.txt"
    assert_equal "bar.txt", shell_output(cmd).chomp
    cmd = "#{bin}/fsql SELECT name FROM . WHERE FORMAT\\(size, GB\\) \\> 500"
    assert_empty shell_output(cmd)
  end
end
