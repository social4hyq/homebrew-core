class Tcptunnel < Formula
  desc "TCP port forwarder"
  homepage "https://vakuumverpackt.de/tcptunnel/"
  url "https://github.com/vakuum/tcptunnel/archive/refs/tags/v0.8.tar.gz"
  sha256 "1926e2636d26570035a5a0292c8d7766c4a9af939881121660df0d0d4513ade4"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5f17f661930e7877133bf0fbafe2655321669cda0407eecab3bd4ebbf0180a9c"
  end

  def install
    bin.mkpath
    # installs directly into the prefix so should use bin
    system "./configure", "--prefix=#{bin}"
    system "make"
    system "make", "install"
  end

  test do
    system bin/"tcptunnel", "--version"
  end
end
