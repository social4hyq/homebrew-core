class Wgetpaste < Formula
  desc "Automate pasting to a number of pastebin services"
  homepage "https://wgetpaste.zlin.dk/"
  url "https://github.com/zlin/wgetpaste/releases/download/2.34/wgetpaste-2.34.tar.xz"
  sha256 "bd6d06ed901a3d63c9c8c57126084ff0994f09901bfb1638b87953eac1e9433f"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "991646ecf95708be6baa7c1899b87da13fc0e130ed0cf57b615db8503836585c"
  end

  depends_on "wget"

  def install
    bin.install "wgetpaste"
    zsh_completion.install "_wgetpaste"
  end

  test do
    system bin/"wgetpaste", "-S"
  end
end
