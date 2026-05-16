class Dylibbundler < Formula
  desc "Utility to bundle libraries into executables for macOS"
  homepage "https://github.com/auriamg/macdylibbundler"
  url "https://github.com/auriamg/macdylibbundler/archive/refs/tags/1.0.5.tar.gz"
  sha256 "13384ebe7ca841ec392ac49dc5e50b1470190466623fa0e5cd30f1c634858530"
  license "MIT"
  head "https://github.com/auriamg/macdylibbundler.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "52b2905320d82c86babb71d7c34dd47ccb8cedc185f94552c020f4cc60a20a1d"
  end

  def install
    system "make"
    bin.install "dylibbundler"
  end

  test do
    system bin/"dylibbundler", "-h"
  end
end
