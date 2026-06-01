class Libredwg < Formula
  desc "DWG utilities"
  homepage "https://www.gnu.org/software/libredwg/"
  url "https://ftpmirror.gnu.org/gnu/libredwg/libredwg-0.13.3.tar.gz"
  sha256 "6fe6c273ecbb04d4a7646e1636ede4815b51f98f974cece649dab341d24feda2"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "782f04f1f304b2096d9713130285aa0996a97a653fcc739d4d0f2ffc24383eeb"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "texinfo" => :build

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    resource "testdata" do
      url "https://github.com/LibreDWG/libredwg/raw/refs/heads/master/test/test-data/example_2000.dwg"
      sha256 "34574244d7556d1ef7b437443d9b3d1ad8662e1c669c42d80cff6a8a19799be9"
    end

    resource("testdata").stage do
      system bin/"dwgread", "-o", "example_2000.dxf", "example_2000.dwg"
      assert_path_exists "example_2000.dxf"
    end
  end
end
