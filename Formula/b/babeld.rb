class Babeld < Formula
  desc "Loop-avoiding distance-vector routing protocol"
  homepage "https://www.irif.fr/~jch/software/babel/"
  url "https://www.irif.fr/~jch/software/files/babeld-1.14.tar.gz"
  sha256 "c4ed13c04880ccc3a85a99645dcb64134beac8ab0607fe32a4d07e1057ad73b7"
  license "MIT"
  head "https://github.com/jech/babeld.git", branch: "master"

  livecheck do
    url "https://www.irif.fr/~jch/software/files/"
    regex(/href=.*?babeld[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f4350ac2d2c7c1bc76faf409b86d40f51dceb305cd2be1e027d19df4dbe156a2"
  end

  def install
    if OS.mac?
      # LDLIBS='' fixes: ld: library not found for -lrt
      system "make", "LDLIBS=''"
    else
      system "make"
    end
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    shell_output("#{bin}/babeld -I #{testpath}/test.pid -L #{testpath}/test.log", 1)
    assert_match "kernel_setup failed", (testpath/"test.log").read
  end
end
