class Mcpp < Formula
  desc "Alternative C/C++ preprocessor"
  homepage "https://mcpp.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/mcpp/mcpp/V.2.7.2/mcpp-2.7.2.tar.gz"
  sha256 "3b9b4421888519876c4fc68ade324a3bbd81ceeb7092ecdbbc2055099fcb8864"
  license "BSD-2-Clause"

  livecheck do
    url :stable
    regex(%r{url=.*?/mcpp[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aab0d8a81a9561f44ab25159c1659e4fc7ad48cef30fe4c4a414083b7d3a2f89"
  end

  # stpcpy is a macro on macOS; trying to define it as an extern is invalid.
  # Patch from ZeroC fixing EOL comment parsing
  # https://forums.zeroc.com/discussion/5445/mishap-in-slice-compilers
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/mcpp/2.7.2.patch"
    sha256 "4bc6a6bd70b67cb78fc48d878cd264b32d7bd0b1ad9705563320d81d5f1abb71"
  end

  def install
    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    # expand.c:713:21: error: assignment to 'char *' from
    # incompatible pointer type 'LOCATION *' {aka 'struct location *'}
    ENV.append_to_cflags "-Wno-error=incompatible-pointer-types"

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", "--enable-mcpplib", *args, *std_configure_args
    system "make", "install"
  end

  test do
    # fix `warning: Unknown encoding: C.utf8`
    ENV["LC_ALL"] = "en_US.UTF-8"

    (testpath/"test.c.in").write <<~C
      #define RET 5
      int main() { return RET; }
    C

    (testpath/"test.c").write shell_output("#{bin}/mcpp test.c.in")
    system ENV.cc, "test.c", "-o", "test"
    assert_empty shell_output("./test", 5)
  end
end
