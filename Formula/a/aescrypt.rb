class Aescrypt < Formula
  desc "Program for encryption/decryption"
  homepage "https://aescrypt.sourceforge.net/"
  url "https://aescrypt.sourceforge.net/aescrypt-0.7.tar.gz"
  sha256 "7b17656cbbd76700d313a1c36824a197dfb776cadcbf3a748da5ee3d0791b92d"
  license "BSD-4-Clause"

  livecheck do
    url :homepage
    regex(/href=.*?aescrypt[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a6747005937b6f1cb26a940284ede976bc65c21ecfa79c25258ce820dbbf8502"
  end

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    # Work around failure from GCC 10+ using default of `-fno-common`
    # multiple definition of `ROUNDS'; aescrypt.o:(.bss+0x180): first defined here
    ENV.append_to_cflags "-fcommon" if OS.linux?

    system "./configure"
    system "make"
    bin.install "aescrypt", "aesget"
  end

  test do
    (testpath/"key").write "kk=12345678901234567890123456789abc0"
    original_text = "hello"
    cipher_text = pipe_output("#{bin}/aescrypt -k #{testpath}/key -s 128", original_text, 0)
    deciphered_text = pipe_output("#{bin}/aesget -k #{testpath}/key -s 128", cipher_text, 0)
    refute_equal original_text, cipher_text
    assert_equal original_text, deciphered_text
  end
end
