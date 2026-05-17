class Wego < Formula
  desc "Weather app for the terminal"
  homepage "https://github.com/schachmat/wego"
  url "https://github.com/schachmat/wego/archive/refs/tags/2.4.tar.gz"
  sha256 "5ae1c76a322ff2e295034a801755c42b0cb6bdef5ab205af42cf95dbf7c570f4"
  license "ISC"
  head "https://github.com/schachmat/wego.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9fe76b893f6f07357494a287b1372906ff587a53af9f6683c908dfa20d955e3c"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    ENV["WEGORC"] = testpath/".wegorc"
    assert_match(/No .*API key specified./, shell_output("#{bin}/wego 2>&1", 1))
  end
end
