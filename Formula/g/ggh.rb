class Ggh < Formula
  desc "Recall your SSH sessions"
  homepage "https://github.com/byawitz/ggh"
  url "https://github.com/byawitz/ggh/archive/refs/tags/v0.1.5.tar.gz"
  sha256 "1adf81aec62040233154843dd18cf575c9485a10d4f46c475708474536422b1b"
  license "Apache-2.0"
  head "https://github.com/byawitz/ggh.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f0c6f788b3a096a7b69283c19cc32e79825e3f6aae1d55ecabbfae8a4f2dbf5b"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "No history found.", shell_output(bin/"ggh").chomp
    assert_match "No config found.", shell_output("#{bin}/ggh -").chomp
  end
end
