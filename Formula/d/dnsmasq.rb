class Dnsmasq < Formula
  desc "Lightweight DNS forwarder and DHCP server"
  homepage "https://thekelleys.org.uk/dnsmasq/doc.html"
  url "https://thekelleys.org.uk/dnsmasq/dnsmasq-2.92.tar.gz"
  sha256 "fd908e79ff37f73234afcb6d3363f78353e768703d92abd8e3220ade6819b1e1"
  license any_of: ["GPL-2.0-only", "GPL-3.0-only"]
  compatibility_version 1

  livecheck do
    url "https://thekelleys.org.uk/dnsmasq/"
    regex(/href=.*?dnsmasq[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d7a0841668a947494732c13d6306fdee28c9fcdc52ad6ff445d779d1e500a298"
  end

  depends_on "pkgconf" => :build

  def install
    ENV.deparallelize

    # Fix etc location
    inreplace %w[dnsmasq.conf.example src/config.h man/dnsmasq.8
                 man/es/dnsmasq.8 man/fr/dnsmasq.8].each do |s|
      s.gsub! "/var/lib/misc/dnsmasq.leases",
              var/"lib/misc/dnsmasq/dnsmasq.leases", audit_result: false
      s.gsub! "/etc/dnsmasq.conf", etc/"dnsmasq.conf", audit_result: false
      s.gsub! "/var/run/dnsmasq.pid", var/"run/dnsmasq/dnsmasq.pid", audit_result: false
      s.gsub! "/etc/dnsmasq.d", etc/"dnsmasq.d", audit_result: false
      s.gsub! "/etc/ppp/resolv.conf", etc/"dnsmasq.d/ppp/resolv.conf", audit_result: false
      s.gsub! "/etc/dhcpc/resolv.conf", etc/"dnsmasq.d/dhcpc/resolv.conf", audit_result: false
      s.gsub! "/usr/sbin/dnsmasq", HOMEBREW_PREFIX/"sbin/dnsmasq", audit_result: false
    end

    # Fix compilation on newer macOS versions.
    ENV.append_to_cflags "-D__APPLE_USE_RFC_3542"

    inreplace "Makefile" do |s|
      s.change_make_var! "CFLAGS", ENV.cflags || ""
      s.change_make_var! "LDFLAGS", ENV.ldflags || ""
    end

    system "make", "install", "PREFIX=#{prefix}"

    etc.install "dnsmasq.conf.example" => "dnsmasq.conf"
    (var/"lib/misc/dnsmasq").mkpath
    (var/"run/dnsmasq").mkpath
    (etc/"dnsmasq.d/ppp").mkpath
    (etc/"dnsmasq.d/dhcpc").mkpath
    touch etc/"dnsmasq.d/ppp/.keepme"
    touch etc/"dnsmasq.d/dhcpc/.keepme"
  end

  def caveats
    <<~EOS
      On current macOS releases, `/etc/resolver/<domain>` resolver overrides do not work if the nameserver is `127.0.0.1` and dnsmasq is running on a non-53 port.
      To use scoped resolver zones reliably, bind dnsmasq to a non-localhost IP (e.g., a loopback alias like 10.0.0.1) on port 53.
    EOS
  end

  service do
    run [opt_sbin/"dnsmasq", "--keep-in-foreground", "-C", etc/"dnsmasq.conf", "-7", etc/"dnsmasq.d,*.conf"]
    keep_alive true
    require_root true
  end

  test do
    system sbin/"dnsmasq", "--test"
  end
end
