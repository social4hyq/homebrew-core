require File.expand_path("../../Abstract/portable-formula", __dir__)

class PortableOpenssl < PortableFormula
  desc "Cryptography and SSL/TLS Toolkit"
  homepage "https://openssl.org/"
  url "https://github.com/openssl/openssl/releases/download/openssl-3.6.4/openssl-3.6.4.tar.gz"
  mirror "https://www.openssl.org/source/openssl-3.6.4.tar.gz"
  mirror "http://fresh-center.net/linux/misc/openssl-3.6.4.tar.gz"
  sha256 "9bffaa1ad1e07b354c21bd3324ec02fa15579f45a7d0494b3e74bc449b7333ef"
  license "Apache-2.0"

  livecheck do
    url "https://openssl-library.org/source/"
    regex(/href=.*?openssl[._-]v?(3(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dbe55955c0b5d8269b959b289ebf00e41d1bfe4955b0c65454d6a1866d1ac8df"
  end

  resource "cacert" do
    # https://curl.se/docs/caextract.html
    url "https://curl.se/ca/cacert-2026-08-13.pem"
    sha256 "f66dff1bdf8f96060b8177976f8b7d9254bc89bc4db933d769f7384d28480bc9"

    livecheck do
      url "https://curl.se/ca/cadate.t"
      regex(/^#define\s+CA_DATE\s+(.+)$/)
      strategy :page_match do |page, regex|
        match = page.match(regex)
        next if match.blank?

        Date.parse(match[1]).iso8601
      end
    end
  end

  def openssldir
    libexec/"etc/openssl"
  end

  def arch_args
    if OS.mac?
      %W[darwin64-#{Hardware::CPU.arch}-cc enable-ec_nistp_64_gcc_128]
    elsif Hardware::CPU.intel?
      if Hardware::CPU.is_64_bit?
        ["linux-x86_64"]
      else
        ["linux-elf"]
      end
    elsif Hardware::CPU.arm?
      if Hardware::CPU.is_64_bit?
        ["linux-aarch64"]
      else
        ["linux-armv4"]
      end
    end
  end

  def configure_args
    %W[
      --prefix=#{prefix}
      --openssldir=#{openssldir}
      --libdir=#{lib}
      no-legacy
      no-module
      no-shared
      no-engine
    ]
  end

  def install
    # OpenSSL is not fully portable and certificate paths are backed into the library.
    # We therefore need to set the certificate path at runtime via an environment variable.
    # We however don't want to touch _other_ OpenSSL usages, so we change the variable name to differ.
    inreplace "include/internal/common.h", "\"SSL_CERT_FILE\"", "\"PORTABLE_RUBY_SSL_CERT_FILE\""

    openssldir.mkpath
    system "perl", "./Configure", *(configure_args + arch_args)
    system "make"

    system "make", "install_dev"

    # Ruby doesn't support passing --static to pkg-config.
    # Unfortunately, this means we need to modify the OpenSSL pc file.
    # This is a Ruby bug - not an OpenSSL one.
    inreplace lib/"pkgconfig/libcrypto.pc", "\nLibs.private:", ""

    cacert = resource("cacert")
    filename = Pathname.new(cacert.url).basename
    openssldir.install cacert.files(filename => "cert.pem")
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <openssl/evp.h>
      #include <stdio.h>
      #include <string.h>

      int main(int argc, char *argv[])
      {
        if (argc < 2)
          return -1;

        unsigned char md[EVP_MAX_MD_SIZE];
        unsigned int size;

        if (!EVP_Digest(argv[1], strlen(argv[1]), md, &size, EVP_sha256(), NULL))
          return 1;

        for (unsigned int i = 0; i < size; i++)
          printf("%02x", md[i]);
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-lcrypto", "-o", "test"
    assert_equal "717ac506950da0ccb6404cdd5e7591f72018a20cbca27c8a423e9c9e5626ac61",
                 shell_output("./test 'This is a test string'")
  end
end
