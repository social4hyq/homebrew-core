class Kona < Formula
  desc "Open-source implementation of the K programming language"
  homepage "https://github.com/kevinlawler/kona"
  url "https://github.com/kevinlawler/kona/archive/refs/tags/Win64-20211225.tar.gz"
  sha256 "cd5dcc03394af275f0416b3cb2914574bf51ec60d1c857020fbd34b5427c5faf"
  license "ISC"
  head "https://github.com/kevinlawler/kona.git", branch: "master"

  livecheck do
    url :stable
    regex(/(?:Win(?:64)?[._-])?v?(\d+(?:\.\d+)*)/i)
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bad1b2f6d26f0adae9972f1dd2264c33e742868ea063a92cf61ac8a3425cd630"
  end

  def install
    system "make"
    bin.install "k"
  end

  test do
    assert_match "Hello, world!", pipe_output("#{bin}/k", '`0: "Hello, world!"')
  end
end
