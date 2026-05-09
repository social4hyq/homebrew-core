class Gsl < Formula
  desc "Numerical library for C and C++"
  homepage "https://www.gnu.org/software/gsl/"
  url "https://ftpmirror.gnu.org/gnu/gsl/gsl-2.8.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gsl/gsl-2.8.tar.gz"
  sha256 "6a99eeed15632c6354895b1dd542ed5a855c0f15d9ad1326c6fe2b2c9e423190"
  license "GPL-3.0-or-later"
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "34cb1e84a35c7c2a121717fa6bac2b8ae4570e1d7ee7e877bb1897fdf0f6f501"
  end

  def install
    system "./configure", *std_configure_args.reject { |s| s["--disable-debug"] }
    system "make"
    system "make", "install"
  end

  test do
    system bin/"gsl-randist", "0", "20", "cauchy", "30"
  end
end
