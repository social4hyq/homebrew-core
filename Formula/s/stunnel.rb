class Stunnel < Formula
  desc "SSL tunneling program"
  homepage "https://www.stunnel.org/"
  url "https://www.stunnel.org/downloads/stunnel-5.80.tar.gz"
  sha256 "6d0841d48de07cbbaf4a055919065bf7bb5ebc63cc15c97a2c76caa2bf285513"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://www.stunnel.org/downloads.html"
    regex(/href=.*?stunnel[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6eac8f2a61b1356a2c776ffc3cdbf307010064b79c7f704ff6975524c4d37a9a"
  end

  depends_on "openssl@3"

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--sysconfdir=#{etc}",
                          "--localstatedir=#{var}",
                          "--mandir=#{man}",
                          "--disable-libwrap",
                          "--disable-systemd",
                          "--with-ssl=#{Formula["openssl@3"].opt_prefix}"
    system "make", "install"

    # This programmatically recreates pem creation used in the tools Makefile
    # which would usually require interactivity to resolve.
    cd "tools" do
      system "dd", "if=/dev/urandom", "of=stunnel.rnd", "bs=256", "count=1"
      system "#{Formula["openssl@3"].opt_bin}/openssl", "req",
        "-new", "-x509",
        "-days", "365",
        "-rand", "stunnel.rnd",
        "-config", "openssl.cnf",
        "-out", "stunnel.pem",
        "-keyout", "stunnel.pem",
        "-sha256",
        "-subj", "/C=PL/ST=Mazovia Province/L=Warsaw/O=Stunnel Developers/OU=Provisional CA/CN=localhost/"
      chmod 0600, "stunnel.pem"
      (etc/"stunnel").install "stunnel.pem"
    end
  end

  def caveats
    <<~EOS
      A bogus SSL server certificate has been installed to:
        #{etc}/stunnel/stunnel.pem

      This certificate will be used by default unless a config file says otherwise!
      Stunnel will refuse to load the sample configuration file if left unedited.

      In your stunnel configuration, specify a SSL certificate with
      the "cert =" option for each service.

      To use Stunnel with Homebrew services, make sure to set "foreground = yes" in
      your Stunnel configuration.
    EOS
  end

  service do
    run [opt_bin/"stunnel"]
  end

  test do
    user = if OS.mac?
      "nobody"
    else
      ENV["USER"]
    end
    (testpath/"tstunnel.conf").write <<~EOS
      cert = #{etc}/stunnel/stunnel.pem
      foreground = yes

      setuid = #{user}
      setgid = #{user}

      [pop3s]
      accept  = 995
      connect = 110

      [imaps]
      accept  = 993
      connect = 143
    EOS

    assert_match "successful", pipe_output("timeout 1s #{bin}/stunnel #{testpath}/tstunnel.conf 2>&1")
  end
end
