class AescryptPacketizer < Formula
  desc "Encrypt and decrypt using 256-bit AES encryption"
  homepage "https://www.aescrypt.com"
  # v3 source is currently removed. See https://forums.packetizer.com/viewtopic.php?t=1777
  # url "https://www.aescrypt.com/download/v3/linux/aescrypt-3.16.tgz"
  url "https://www.mirrorservice.org/sites/distfiles.gentoo.org/distfiles/13/aescrypt-3.16.tgz"
  sha256 "e2e192d0b45eab9748efe59e97b656cc55f1faeb595a2f77ab84d44b0ec084d2"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "82d3e2163be29c0b47e7b6ca88e0938f27df31c80af6f1a32edfa528bedfd2c7"
  end

  # v3 source code has been unavailable since at least 2024-09-01.
  # v4 requires purchase of license (https://www.aescrypt.com/license.html)
  deprecate! date: "2025-03-17", because: "switched to a commercial license in v4"
  disable! date: "2026-03-17", because: "switched to a commercial license in v4"

  def install
    if build.head?
      cd "Linux"
      system "autoreconf", "--force", "--install", "--verbose"

      args = ["--disable-gui"]
      args << "--enable-iconv" if OS.mac?

      system "./configure", *args, *std_configure_args
      system "make", "install"
    else
      system "make"
      bin.install "src/aescrypt"
      bin.install "src/aescrypt_keygen"
      man1.install "man/aescrypt.1"
    end

    # To prevent conflict with our other aescrypt, rename the binaries.
    mv "#{bin}/aescrypt", "#{bin}/paescrypt"
    mv "#{bin}/aescrypt_keygen", "#{bin}/paescrypt_keygen"
  end

  def caveats
    <<~EOS
      To avoid conflicting with our other AESCrypt package the binaries
      have been renamed paescrypt and paescrypt_keygen.
    EOS
  end

  test do
    path = testpath/"secret.txt"
    original_contents = "What grows when it eats, but dies when it drinks?"
    path.write original_contents

    system bin/"paescrypt", "-e", "-p", "fire", path
    assert_path_exists testpath/"#{path}.aes"

    system bin/"paescrypt", "-d", "-p", "fire", "#{path}.aes"
    assert_equal original_contents, path.read
  end
end
