class Cln < Formula
  desc "Class Library for Numbers"
  homepage "https://www.ginac.de/CLN/"
  url "https://www.ginac.de/CLN/cln-1.3.7.tar.bz2"
  sha256 "7c7ed8474958337e4df5bb57ea5176ad0365004cbb98b621765bc4606a10d86b"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?cln[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b11416aca186dcd8fe95aa57a45a35dce51aebce5c8b60ca6eb7f402de7a7e79"
  end

  head do
    url "git://www.ginac.de/cln.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "wget" => :build

    on_system :linux, macos: :ventura_or_newer do
      depends_on "texinfo" => :build
    end
  end

  depends_on "gmp"

  def install
    system "./autogen.sh" if build.head?
    system "./configure", *std_configure_args
    system "make"
    system "make", "check"
    system "make", "install"
  end

  test do
    assert_match "3.14159", shell_output("#{bin}/pi 6")
  end
end
