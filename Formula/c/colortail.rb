class Colortail < Formula
  desc "Like tail(1), but with various colors for specified output"
  homepage "https://github.com/joakim666/colortail"
  url "https://github.com/joakim666/colortail/releases/download/0.3.5/colortail-0.3.5.tar.gz"
  sha256 "8d259560c6f4a4aaf1f4bbdb2b62d3e1053e7e19fefad7de322131b7e80e294d"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7b073bc585d5767f28dbfd449bc086d08a1067f2c4a27fb61818d97df6fd2c68"
  end

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.txt").write "Hello\nWorld!\n"
    assert_match(/World!/, shell_output("#{bin}/colortail -n 1 test.txt"))
  end
end
