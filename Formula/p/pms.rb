class Pms < Formula
  desc "Practical Music Search, an ncurses-based MPD client"
  homepage "https://kimtore.github.io/pms/"
  url "https://downloads.sourceforge.net/project/pms/pms/0.42/pms-0.42.tar.bz2"
  sha256 "96bf942b08cba10ee891a63eeccad307fd082ef3bd20be879f189e1959e775a6"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c6862fc84166677a14426d17793ce90e117f7c40b11888929173806f768dd80b"
  end

  depends_on "pkgconf" => :build

  depends_on "gettext"
  depends_on "glib"

  uses_from_macos "ncurses"

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/pms -?", 4)
    assert_match "Practical Music Search v#{version}", output
  end
end
