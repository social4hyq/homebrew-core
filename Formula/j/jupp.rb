class Jupp < Formula
  desc "Professional screen editor for programmers"
  homepage "https://mbsd.evolvis.org/jupp.htm"
  url "https://mbsd.evolvis.org/MirOS/dist/jupp/joe-3.1jupp41.tgz"
  version "3.1jupp41"
  sha256 "7bb8ea8af519befefff93ec3c9e32108d7f2b83216c9bc7b01aef5098861c82f"
  license "GPL-1.0-or-later"
  # Upstream HEAD in CVS: http://www.mirbsd.org/cvs.cgi/contrib/code/jupp/

  livecheck do
    url :homepage
    regex(/href=.*?joe[._-]v?(\d+(?:\.\d+)+jupp\d+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9825e95c1d9131c0af5957faa2e864cded539758e52881e14773f837acb97556"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  uses_from_macos "ncurses"

  on_macos do
    depends_on "gnu-sed" => :build
  end

  conflicts_with "joe", because: "both install the same binaries"

  def install
    ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin" if OS.mac?
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--enable-sysconfjoesubdir=/jupp", *std_configure_args
    system "make", "install"
  end

  test do
    require "pty"
    output = ""
    PTY.spawn({ "TERM" => "xterm" }, bin/"jupp", "test") do |r, w, _pid|
      w.write "brewx"
      begin
        r.each { |line| output += line }
      rescue Errno::EIO
        # GNU/Linux raises EIO when read is done on closed pty
      end
    end
    assert_match "File test saved", output
    assert_equal "brew", (testpath/"test").read
  end
end
