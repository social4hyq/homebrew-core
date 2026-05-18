class Doubledown < Formula
  desc "Sync local changes to a remote directory"
  homepage "https://github.com/devstructure/doubledown"
  url "https://github.com/devstructure/doubledown/archive/refs/tags/v0.0.2.tar.gz"
  sha256 "47ff56b6197c5302a29ae4a373663229d3b396fd54d132adbf9f499172caeb71"
  license "BSD-2-Clause"
  head "https://github.com/devstructure/doubledown.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "85cbc0860332ec6e0a5f81b4e268ffc5ef071e3da6e0e13fbf0dafce63554a46"
  end

  def install
    bin.install Dir["bin/*"]
    man1.install Dir["man/man1/*.1"]
  end

  test do
    system bin/"doubledown", "--help"
  end
end
