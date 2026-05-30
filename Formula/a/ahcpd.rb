class Ahcpd < Formula
  desc "Autoconfiguration protocol for IPv6 and IPv6/IPv4 networks"
  homepage "https://www.irif.fr/~jch/software/ahcp/"
  url "https://www.irif.fr/~jch/software/files/ahcpd-0.53.tar.gz"
  sha256 "a4622e817d2b2a9b878653f085585bd57f3838cc546cca6028d3b73ffcac0d52"
  license "MIT"

  livecheck do
    url "https://www.irif.fr/~jch/software/files/"
    regex(/href=.*?ahcpd[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c4f7aaa324528bc0bf8eb21f4868789dee75ebf74ec8ab6cfcba6edc2eeee064"
  end

  patch :DATA

  def install
    if OS.mac?
      # LDLIBS='' fixes: ld: library not found for -lrt
      system "make", "LDLIBS=''"
    else
      system "make"
    end
    system "make", "install", "PREFIX=", "TARGET=#{prefix}"
  end

  test do
    pid_file = testpath/"ahcpd.pid"
    log_file = testpath/"ahcpd.log"
    mkdir testpath/"leases"

    (testpath/"ahcpd.conf").write <<~EOS
      mode server

      prefix fde6:20f5:c9ac:358::/64
      prefix 192.168.4.128/25
      lease-dir #{testpath}/leases
      name-server fde6:20f5:c9ac:358::1
      name-server 192.168.4.1
      ntp-server 192.168.4.2
    EOS

    system bin/"ahcpd", "-c", "ahcpd.conf", "-I", pid_file, "-L", log_file, "-D", "lo0"
    sleep(2)

    assert_path_exists pid_file, "The file containing the PID of the child process was not created."
    assert_path_exists log_file, "The file containing the log was not created."

    Process.kill("TERM", pid_file.read.to_i)
  end
end

__END__
diff --git a/Makefile b/Makefile
index e52eeb7..28e1043 100644
--- a/Makefile
+++ b/Makefile
@@ -40,8 +40,8 @@ install.minimal: all
	chmod +x $(TARGET)/etc/ahcp/ahcp-config.sh

 install: all install.minimal
-	mkdir -p $(TARGET)$(PREFIX)/man/man8/
-	cp -f ahcpd.man $(TARGET)$(PREFIX)/man/man8/ahcpd.8
+	mkdir -p $(TARGET)$(PREFIX)/share/man/man8/
+	cp -f ahcpd.man $(TARGET)$(PREFIX)/share/man/man8/ahcpd.8

 .PHONY: uninstall

@@ -49,7 +49,7 @@ uninstall:
	-rm -f $(TARGET)$(PREFIX)/bin/ahcpd
	-rm -f $(TARGET)$(PREFIX)/bin/ahcp-config.sh
	-rm -f $(TARGET)$(PREFIX)/bin/ahcp-dummy-config.sh
-	-rm -f $(TARGET)$(PREFIX)/man/man8/ahcpd.8
+	-rm -f $(TARGET)$(PREFIX)/share/man/man8/ahcpd.8

 .PHONY: clean
