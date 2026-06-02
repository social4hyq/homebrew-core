class Pkcs11Tools < Formula
  desc "Tools to manage objects on PKCS#11 crypotographic tokens"
  homepage "https://github.com/Mastercard/pkcs11-tools"
  url "https://github.com/Mastercard/pkcs11-tools/releases/download/v2.6.0/pkcs11-tools-2.6.0.tar.gz"
  sha256 "5fcda842ed009dacef5d935f5d46bda81bdc26795737af525aa904655a640ba0"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6a14daf393386a21146d95b90ff670a891e6798a97a4cde347cabab15947cdfb"
  end

  depends_on "pkgconf" => :build
  depends_on "softhsm" => :test
  depends_on "openssl@3"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build

  # Fix Linux build error using gnulib upstream commit.
  # ../gl/string.h:965:1: error: expected ',' or ';' before '_GL_ATTRIBUTE_MALLOC'
  # Remove when the gnulib submodule is updated and available in a release
  patch :p2 do
    on_linux do
      url "https://git.savannah.gnu.org/cgit/gnulib.git/patch/lib?id=cc91160a1ea5e18fcb2ccadb32e857d365581f53"
      directory "gl"
    end
  end

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    # configure new softhsm token, generate a token key, and use it
    mkdir testpath/"tokens"
    softhsm_conf = testpath/"softhsm.conf"

    softhsm_conf.write <<~EOS
      directories.tokendir = #{testpath}/tokens
      directories.backend = file
      log.level = INFO
      slots.removable = false
      slots.mechanisms = ALL
      library.reset_on_fork = false
    EOS

    ENV["SOFTHSM2_CONF"] = softhsm_conf
    ENV["PKCS11LIB"] = Formula["softhsm"].lib/"softhsm/libsofthsm2.so"
    ENV["PKCS11TOKENLABEL"] = "test"
    ENV["PKCS11PASSWORD"] = "0000"

    system "softhsm2-util", "--init-token", "--slot", "0", "--label", "test", "--pin", "0000", "--so-pin", "0000"
    system bin/"p11keygen", "-i", "test", "-k", "aes", "-b", "128", "encrypt"
    system bin/"p11kcv", "seck/test"
    system bin/"p11ls"
  end
end
