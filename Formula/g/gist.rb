class Gist < Formula
  desc "Command-line utility for uploading Gists"
  homepage "https://defunkt.io/gist/"
  url "https://github.com/defunkt/gist/archive/refs/tags/v6.0.0.tar.gz"
  sha256 "ddfb33c039f8825506830448a658aa22685fc0c25dbe6d0240490982c4721812"
  license "MIT"
  head "https://github.com/defunkt/gist.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d31bbd9f4a8e158a4f62af8fcff00c5bc17661fb254631b1deeb4bbd844bc80f"
  end

  uses_from_macos "ruby"

  def install
    system "rake", "install", "prefix=#{prefix}"
  end

  test do
    output = pipe_output(bin/"gist", "homebrew")
    assert_match "GitHub now requires credentials", output
  end
end
