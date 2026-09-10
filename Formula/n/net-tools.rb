class NetTools < Formula
  desc "Linux networking base tools"
  homepage "https://sourceforge.net/projects/net-tools/"
  url "https://downloads.sourceforge.net/project/net-tools/net-tools-2.10.tar.xz"
  sha256 "b262435a5241e89bfa51c3cabd5133753952f7a7b7b93f32e08cb9d96f580d69"
  license "GPL-2.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "41334c83070c1ffcd24bf7d9d9ab9059f586fc37bbf5b78e7cbb6527fc750dd8"
  end

  depends_on "libdnet"
  depends_on :linux

  def install
    inreplace "hostname.c", "rindex", "strrchr"
    inreplace "netstat.c", "rindex", "strrchr"

    # Support non-interactive configuration
    inreplace "configure.sh", "IFS='@' read ans || exit 1", ""

    system "make", "config"
    system "make"
    system "make", "DESTDIR=#{prefix}", "install"
  end

  test do
    assert_match "Kernel Interface table", shell_output("#{bin}/netstat -i")
  end
end
