class Libscrypt < Formula
  desc "Library for scrypt"
  homepage "https://github.com/technion/libscrypt"
  url "https://github.com/technion/libscrypt/archive/refs/tags/v1.22.tar.gz"
  sha256 "a2d30ea16e6d288772791de68be56153965fe4fd4bcd787777618b8048708936"
  license "BSD-2-Clause"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "159b7b4f7b7e59c0bb9b2dfa8478d730c49933cca9a4ed0fd116d26c699479dc"
  end

  # Backport fix for aliasing violations
  patch do
    url "https://github.com/technion/libscrypt/commit/7b574b9c517a3d1f9bd0e265a5f287155293cb85.patch?full_index=1"
    sha256 "5f3b4eaef826191318b57d1c0fe2889d76d18bf17746af2ba5417ccf27ec039f"
  end

  def install
    args = ["PREFIX=#{prefix}"]
    install_target = "install"

    if OS.mac?
      args += %w[CFLAGS_EXTRA=-fstack-protector LDFLAGS= LDFLAGS_EXTRA=]
      install_target << "-osx"
    end

    system "make", "check", *args
    system "make", install_target, *args
    system "make", "install-static", *args

    return if OS.mac?

    prefix.install "libscrypt.version"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libscrypt.h>
      int main(void) {
        char buf[SCRYPT_MCF_LEN];
        libscrypt_hash(buf, "Hello, Homebrew!", SCRYPT_N, SCRYPT_r, SCRYPT_p);
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lscrypt", "-o", "test"
    system "./test"
  end
end
