class Cntlm < Formula
  desc "NTLM authentication proxy with tunneling"
  homepage "https://cntlm.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/cntlm/cntlm/cntlm%200.92.3/cntlm-0.92.3.tar.bz2"
  sha256 "7b603d6200ab0b26034e9e200fab949cc0a8e5fdd4df2c80b8fc5b1c37e7b930"
  license "GPL-2.0-only"
  revision 1

  livecheck do
    url :stable
    regex(%r{url=.*?/cntlm[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2b146c092f7d0360f6b8b184e9e0e7890648bac625f9ed0b52054ec1688c000c"
  end

  def install
    system "./configure"
    system "make", "CC=#{ENV.cc}", "SYSCONFDIR=#{etc}"
    # install target fails - @adamv
    bin.install "cntlm"
    man1.install "doc/cntlm.1"
    etc.install "doc/cntlm.conf"
  end

  def caveats
    "Edit #{etc}/cntlm.conf to configure Cntlm"
  end

  service do
    run [opt_bin/"cntlm", "-f"]
    require_root true
  end

  test do
    assert_match "version #{version}", shell_output("#{bin}/cntlm -h 2>&1", 1)

    bind_port = free_port
    (testpath/"cntlm.conf").write <<~EOS
      # Cntlm Authentication Proxy Configuration
      Username	testuser
      Domain		corp-uk
      Password	password
      Proxy		localhost:#{free_port}
      NoProxy		localhost, 127.0.0.*, 10.*, 192.168.*
      Listen		#{bind_port}
    EOS

    spawn bin/"cntlm", "-c", testpath/"cntlm.conf", "-v"
    sleep 2
    # "unreacheable" is a typo in upstreams code. There haven't been
    # any updates to `cntlm` in over a decade, so this can't be fixed.
    assert_match "502 Parent proxy unreacheable", shell_output("curl -s localhost:#{bind_port}")
  end
end
