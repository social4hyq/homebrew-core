class Puf < Formula
  desc "Parallel URL fetcher"
  homepage "https://puf.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/puf/puf/1.0.0/puf-1.0.0.tar.gz"
  sha256 "3f1602057dc47debeb54effc2db9eadcffae266834389bdbf5ab14fc611eeaf0"
  license "GPL-2.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "48692996548478d76206207ca8580a9974fa943ef8a25732e677226721c1c244"
  end

  def install
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", "--mandir=#{man}", *args, *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"puf", "-r", "example.com"
  end
end
