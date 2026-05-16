class Quictls < Formula
  desc "TLS/SSL and crypto library with QUIC APIs"
  homepage "https://github.com/quictls/openssl"
  url "https://github.com/quictls/openssl/archive/refs/tags/openssl-3.3.0-quic1.tar.gz"
  version "3.3.0-quic1"
  sha256 "78d675d94c0ac3a8b44073f0c2b373d948c5afd12b25c9e245262f563307a566"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^openssl[._-]v?(\d(?:\.\d)+[+._-]quic\d*)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "06ef77b6d5425f4ef89f0de20aaf9a57bd67682db2d9460971f5467d21d6e931"
  end

  keg_only "it conflicts with OpenSSL"

  deprecate! date: "2025-10-02", because: :repo_archived

  depends_on "ca-certificates"

  on_linux do
    resource "Test::Harness" do
      url "https://cpan.metacpan.org/authors/id/L/LE/LEONT/Test-Harness-3.50.tar.gz"
      sha256 "79b6acdc444f1924cd4c2e9ed868bdc6e09580021aca8ff078ede2ffef8a6f54"
    end

    resource "Test::More" do
      url "https://cpan.metacpan.org/authors/id/E/EX/EXODIST/Test-Simple-1.302204.tar.gz"
      sha256 "03749d1027a7817ca7f11e420ef72951f20a849ea65af2eb595f34df47d1226e"
    end

    resource "ExtUtils::MakeMaker" do
      url "https://cpan.metacpan.org/authors/id/B/BI/BINGOS/ExtUtils-MakeMaker-7.70.tar.gz"
      sha256 "f108bd46420d2f00d242825f865b0f68851084924924f92261d684c49e3e7a74"
    end
  end

  def install
    if OS.linux?
      ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"

      resources.each do |r|
        r.stage do
          system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
          system "make", "PERL5LIB=#{ENV["PERL5LIB"]}", "CC=#{ENV.cc}"
          system "make", "install"
        end
      end
    end

    # This could interfere with how we expect OpenSSL to build.
    ENV.delete("OPENSSL_LOCAL_CONFIG_DIR")

    # This ensures where Homebrew's Perl is needed the Cellar path isn't
    # hardcoded into OpenSSL's scripts, causing them to break every Perl update.
    # Whilst our env points to opt_bin, by default OpenSSL resolves the symlink.
    ENV["PERL"] = Formula["perl"].opt_bin/"perl" if which("perl") == Formula["perl"].opt_bin/"perl"

    # SSLv2 died with 1.1.0, so no-ssl2 no longer required.
    # SSLv3 & zlib are off by default with 1.1.0 but this may not
    # be obvious to everyone, so explicitly state it for now to
    # help debug inevitable breakage.
    args = %W[
      --prefix=#{prefix}
      --openssldir=#{quictlsdir}
      --libdir=#{lib}
      no-ssl3
      no-ssl3-method
      no-zlib
    ]

    if OS.linux?
      args += (ENV.cflags || "").split
      args += (ENV.cppflags || "").split
      args += (ENV.ldflags || "").split
    end

    if OS.mac?
      args += %W[darwin64-#{Hardware::CPU.arch}-cc enable-ec_nistp_64_gcc_128]
    elsif Hardware::CPU.intel?
      args << (Hardware::CPU.is_64_bit? ? "linux-x86_64" : "linux-elf")
    elsif Hardware::CPU.arm?
      args << (Hardware::CPU.is_64_bit? ? "linux-aarch64" : "linux-armv4")
    end

    quictlsdir.mkpath
    system "perl", "./Configure", *args
    system "make"
    system "make", "install", "MANDIR=#{man}", "MANSUFFIX=ssl"
    system "make", "test"
  end

  def quictlsdir
    etc/"quictls"
  end

  def post_install
    rm(quictlsdir/"cert.pem") if (quictlsdir/"cert.pem").exist?
    quictlsdir.install_symlink Formula["ca-certificates"].pkgetc/"cert.pem"
  end

  def caveats
    <<~EOS
      A CA file has been bootstrapped using certificates from the system
      keychain. To add additional certificates, place .pem files in
        #{quictlsdir}/certs

      and run
        #{opt_bin}/c_rehash
    EOS
  end

  test do
    # Make sure the necessary .cnf file exists, otherwise OpenSSL gets moody.
    assert_path_exists pkgetc/"openssl.cnf", "OpenSSL requires the .cnf file for some functionality"

    # Check OpenSSL itself functions as expected.
    (testpath/"testfile.txt").write("This is a test file")
    expected_checksum = "e2d0fe1585a63ec6009c8016ff8dda8b17719a637405a4e23c0ff81339148249"
    system bin/"openssl", "dgst", "-sha256", "-out", "checksum.txt", "testfile.txt"
    open("checksum.txt") do |f|
      checksum = f.read(100).split("=").last.strip
      assert_equal checksum, expected_checksum
    end
  end
end
