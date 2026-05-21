class N < Formula
  desc "Node version management"
  homepage "https://github.com/tj/n"
  url "https://github.com/tj/n/archive/refs/tags/v10.2.0.tar.gz"
  sha256 "5914f0d5e89aadaaaeb803baa89a7582747b0c57ad30201b3522cd76f504c7d9"
  license "MIT"
  head "https://github.com/tj/n.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0b27f1a3398d692b29b95ea15a4e6d1b1b4087d1c9c23cfbdb77de985c0aea37"
  end

  def install
    bin.mkdir
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    system bin/"n", "ls"
  end
end
