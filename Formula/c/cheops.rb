class Cheops < Formula
  desc "CHEss OPponent Simulator"
  homepage "https://logological.org/cheops"
  url "https://files.nothingisreal.com/software/cheops/cheops-1.3.tar.bz2"
  mirror "https://github.com/logological/cheops/releases/download/1.3/cheops-1.3.tar.bz2"
  sha256 "a3ce2e94f73068159827a1ec93703b5075c7edfdf5b0c1aba4d71b3e43fe984e"
  license "GPL-3.0-or-later"

  livecheck do
    url "https://files.nothingisreal.com/software/cheops/"
    regex(/href=.*?cheops[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d366608134ababfa93a3261712f386f4c52ff50a07e34236ddfcb707c1d56eba"
  end

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"cheops", "--version"
  end
end
