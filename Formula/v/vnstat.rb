class Vnstat < Formula
  desc "Console-based network traffic monitor"
  homepage "https://humdi.net/vnstat/"
  url "https://humdi.net/vnstat/vnstat-2.13.tar.gz"
  sha256 "c9fe19312d1ec3ddfbc4672aa951cf9e61ca98dc14cad3d3565f7d9803a6b187"
  license "GPL-2.0-only"
  head "https://github.com/vergoh/vnstat.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a679a614a0ec6c2dc517a61bc734b1d67e7c0d7e944eeff855ac029303f54eef"
  end

  depends_on "gd"

  uses_from_macos "sqlite"

  def install
    inreplace %w[src/cfg.c src/common.h man/vnstat.1 man/vnstatd.8 man/vnstati.1
                 man/vnstat.conf.5].each do |s|
      s.gsub! "/etc/vnstat.conf", "#{etc}/vnstat.conf", audit_result: false
      s.gsub! "/var/", "#{var}/", audit_result: false
      s.gsub! "var/lib", "var/db", audit_result: false
      # https://github.com/Homebrew/homebrew-core/pull/84695#issuecomment-913043888
      # network interface difference between macos and linux
      s.gsub! "\"eth0\"", "\"en0\"", audit_result: false if OS.mac?
    end

    system "./configure", "--disable-silent-rules",
                          "--localstatedir=#{var}",
                          "--sbindir=#{bin}",
                          "--sysconfdir=#{etc}",
                          *std_configure_args
    system "make", "install"

    (var/"db/vnstat").mkpath
    (var/"log/vnstat").mkpath
    (var/"run/vnstat").mkpath
  end

  def caveats
    <<~EOS
      To monitor interfaces other than "en0" edit #{etc}/vnstat.conf
    EOS
  end

  service do
    run [opt_bin/"vnstatd", "--nodaemon", "--config", etc/"vnstat.conf"]
    keep_alive true
    require_root true
    working_dir var
    process_type :background
  end

  test do
    cp etc/"vnstat.conf", testpath
    inreplace "vnstat.conf", var, testpath/"var"
    inreplace "vnstat.conf", ";Interface", "Interface"
    inreplace "vnstat.conf", ";DatabaseDir", "DatabaseDir"
    (testpath/"var/db/vnstat").mkpath

    begin
      stat = IO.popen("#{bin}/vnstatd --nodaemon --config vnstat.conf")
      sleep 1
      sleep 2 if OS.mac? && Hardware::CPU.intel?
    ensure
      Process.kill "SIGINT", stat.pid
      Process.wait stat.pid
    end
    assert_match "Info: Monitoring", stat.read
  end
end
