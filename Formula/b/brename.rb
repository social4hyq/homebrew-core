class Brename < Formula
  desc "Cross-platform command-line tool for safe batch renaming via regular expressions"
  homepage "https://github.com/shenwei356/brename"
  url "https://github.com/shenwei356/brename/archive/refs/tags/v2.14.0.tar.gz"
  sha256 "a16bceb25a75afa14c5dae2248c1244f1083b80b62783ce5dbf3e46ff68867d5"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "46e71582b17b9f9e9207e5f53cf02b2292f04e69a1c79ccc0994d7920fea4b70"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(tags: "netgo", ldflags: "-s -w")
  end

  test do
    (1..9).each do |n|
      (testpath/"Homebrew-#{n}.txt").write n.to_s
    end

    system bin/"brename", "-p", "Homebrew-(\\d+).txt", "-r", "$1.txt", "-v", "0"

    (1..9).each do |n|
      assert_equal n.to_s, (testpath/"#{n}.txt").read
      refute_path_exists testpath/"Homebrew-#{n}.txt"
    end
  end
end
