class Fzy < Formula
  desc "Fast, simple fuzzy text selector with an advanced scoring algorithm"
  homepage "https://github.com/jhawthorn/fzy"
  url "https://github.com/jhawthorn/fzy/archive/refs/tags/1.1.tar.gz"
  sha256 "93d300d9c6c7063b2c6bda4e08a9704a029ec33f609718cd95443d1a890aff4e"
  license "MIT"
  head "https://github.com/jhawthorn/fzy.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6976f0de4d31a2085026416f9144c5a14074d14d611845d9bdae22a18ef0deaf"
  end

  def install
    system "make"
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    assert_equal "foo", pipe_output("#{bin}/fzy -e foo", "bar\nfoo\nqux").chomp
  end
end
