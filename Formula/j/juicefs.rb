class Juicefs < Formula
  desc "Cloud-based, distributed POSIX file system built on top of Redis and S3"
  homepage "https://juicefs.com"
  url "https://github.com/juicedata/juicefs/archive/refs/tags/v1.4.0.tar.gz"
  sha256 "3122b9f608bfdc6a477d73ec38b13c30ce6b07a09e046c61a37042153f35e0d3"
  license "Apache-2.0"
  head "https://github.com/juicedata/juicefs.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6eae958263bae28bcfda672746d60fab93020b6f61c6974955069c7d0a6949dd"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "1" if OS.linux? && Hardware::CPU.arm?

    system "make"
    bin.install "juicefs"
  end

  test do
    output = shell_output("#{bin}/juicefs format sqlite3://test.db testfs 2>&1")
    assert_path_exists testpath/"test.db"
    assert_match "Meta address: sqlite3://test.db", output
  end
end
