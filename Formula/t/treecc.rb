class Treecc < Formula
  desc "Aspect-oriented approach to writing compilers"
  homepage "https://gnu.org/software/dotgnu/treecc/treecc.html"
  url "https://download.savannah.gnu.org/releases/dotgnu-pnet/treecc-0.3.10.tar.gz"
  sha256 "5e9d20a6938e0c6fedfed0cabc7e9e984024e4881b748d076e8c75f1aeb6efe7"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://download.savannah.gnu.org/releases/dotgnu-pnet/"
    regex(/href=.*?treecc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "51ab4d958ea45d3a8a8e62eaf1b07eb302e4fdd9c26f6f33e3f8fa6bc8b43b48"
  end

  def install
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make"
    bin.install "treecc"
  end

  test do
    system bin/"treecc", "-v"
  end
end
