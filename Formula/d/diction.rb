class Diction < Formula
  desc "GNU diction and style"
  homepage "https://www.gnu.org/software/diction/"
  url "https://ftpmirror.gnu.org/gnu/diction/diction-1.11.tar.gz"
  mirror "https://ftp.gnu.org/gnu/diction/diction-1.11.tar.gz"
  sha256 "35c2f1bf8ddf0d5fa9f737ffc8e55230736e5d850ff40b57fdf5ef1d7aa024f6"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b4c863426851dc20fb1a487b5a4d4b3f4a3c3c49482fe3aaf6c5995d66541358"
  end

  def install
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    file = "test.txt"
    (testpath/file).write "The quick brown fox jumps over the lazy dog."
    assert_match(/^.*35 characters.*9 words.*$/m, shell_output("#{bin}/style #{file}"))
    assert_match "No phrases in 1 sentence found.", shell_output("#{bin}/diction #{file}")
  end
end
