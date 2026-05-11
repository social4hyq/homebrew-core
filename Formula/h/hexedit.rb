class Hexedit < Formula
  desc "View and edit files in hexadecimal or ASCII"
  homepage "https://rigaux.org/hexedit.html"
  url "https://github.com/pixel/hexedit/archive/refs/tags/1.6.tar.gz"
  sha256 "598906131934f88003a6a937fab10542686ce5f661134bc336053e978c4baae3"
  license "GPL-2.0-or-later"
  head "https://github.com/pixel/hexedit.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4d1cc73aea6b9376d504802ae40d9974a75827b7dd132762851983f6f5bbeccf"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  uses_from_macos "ncurses"

  def install
    system "./autogen.sh"
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    shell_output("#{bin}/hexedit -h 2>&1", 1)
  end
end
