class Vbindiff < Formula
  desc "Visual Binary Diff"
  homepage "https://www.cjmweb.net/vbindiff/"
  url "https://www.cjmweb.net/vbindiff/vbindiff-3.0_beta5.tar.gz"
  sha256 "f04da97de993caf8b068dcb57f9de5a4e7e9641dc6c47f79b60b8138259133b8"
  license "GPL-2.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?vbindiff[._-]v?(\d+(?:\.\d+)+(?:.?beta\d+)?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "54372d04225d4d76d158992c7f18da932fde058b9b2a1d167ac23bbb32130199"
  end

  uses_from_macos "ncurses"

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"vbindiff", "-L"
  end
end
