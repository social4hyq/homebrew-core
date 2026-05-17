class Mussh < Formula
  desc "Multi-host SSH wrapper"
  homepage "https://mussh.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/mussh/mussh/1.0/mussh-1.0.tgz"
  sha256 "6ba883cfaacc3f54c2643e8790556ff7b17da73c9e0d4e18346a51791fedd267"
  license "GPL-1.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d1fe87f4c41a60deb46f30155ec8fa5f738b75692fdead9aeb1db15fdcc4339a"
  end

  def install
    bin.install "mussh"
    man1.install "mussh.1"
  end

  test do
    system bin/"mussh", "--help"
  end
end
