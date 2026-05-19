class Thrulay < Formula
  desc "Measure performance of a network"
  homepage "https://sourceforge.net/projects/thrulay/"
  url "https://downloads.sourceforge.net/project/thrulay/thrulay/0.9/thrulay-0.9.tar.gz"
  sha256 "373d5613dfe371f6b4f48fc853f6c27701b2981ba4100388c9881cb802d1780d"
  # Similar to BSD-3-Clause-LBNL (i.e. BSD-3-Clause with an additional default
  # contribution licensing clause) but different phrasing from the SPDX license
  license :cannot_represent

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e1ed14fc7515378faf87e15c2f5ee5582cc1c4af3364200931a4a31235b3f838"
  end

  def install
    # Fix flat namespace usage
    inreplace "configure", "${wl}-flat_namespace ${wl}-undefined ${wl}suppress", "${wl}-undefined ${wl}dynamic_lookup"

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    ENV.deparallelize
    system "make", "install"
  end

  test do
    # prints "thrulay/2 (client part) release 0.9rc1"
    system bin/"thrulay", "-V"
  end
end
