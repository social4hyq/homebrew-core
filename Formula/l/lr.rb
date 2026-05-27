class Lr < Formula
  desc "File list utility with features from ls(1), find(1), stat(1), and du(1)"
  homepage "https://github.com/leahneukirchen/lr"
  url "https://github.com/leahneukirchen/lr/archive/refs/tags/v2.0.1.tar.gz"
  sha256 "c7c4a57169e1396f17a09b05b19456945c8bb5e55001c5a870b083c0b4a23cd8"
  license "MIT"
  head "https://github.com/leahneukirchen/lr.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cb8255dd1b8202fbe8d42e4e4529b280ea98a4804002fe6cbbe358229f9f011b"
  end

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    assert_match(/^\.\n(.*\n)?\.bazelrc\n/, shell_output("#{bin}/lr -1"))
  end
end
