class DbVcs < Formula
  desc "Version control for MySQL databases"
  homepage "https://github.com/infostreams/db"
  url "https://github.com/infostreams/db/archive/refs/tags/1.1.tar.gz"
  sha256 "90f07c13c388896ba02032544820f8ff3a23e6f9dc1e320a1a653dd77e032ee7"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2f45dc7a0cd1605d14c393cd8e678f5573b5d56d3af1e44f41221e1c65a1a329"
  end

  def install
    libexec.install "db"
    libexec.install "bin/"
    bin.install_symlink libexec/"db"
  end

  test do
    output = shell_output("#{bin}/db server add localhost", 2)
    assert_match "fatal: Not a db repository", output
  end
end
