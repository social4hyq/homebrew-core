class Daemon < Formula
  desc "Turn other processes into daemons"
  homepage "https://libslack.org/daemon/"
  url "https://libslack.org/daemon/download/daemon-0.8.4.tar.gz"
  sha256 "fa28859ad341cb0a0b012c11c271814f870482013b49f710600321d379887cd1"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?daemon[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21ea729927d77808eef87a7ec3b2d365f1cc3df45431000a22a3808b986bd881"
  end

  def install
    system "./configure"
    system "make"
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    system bin/"daemon", "--version"
  end
end
