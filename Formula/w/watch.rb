class Watch < Formula
  desc "Executes a program periodically, showing output fullscreen"
  homepage "https://gitlab.com/procps-ng/procps"
  url "https://downloads.sourceforge.net/project/procps-ng/Production/procps-ng-4.0.6.tar.xz"
  sha256 "67bea6fbc3a42a535a0230c9e891e5ddfb4d9d39422d46565a2990d1ace15216"
  license all_of: ["GPL-2.0-or-later", "LGPL-2.1-or-later"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "49245c93310a51a5acd50e3fc350bb59f0058953e1b0168f81304a834bcaacf0"
  end

  head do
    url "https://gitlab.com/procps-ng/procps.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "gettext" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "ncurses"

  conflicts_with "visionmedia-watch"

  def install
    args = %w[
      --disable-nls
      --enable-watch8bit
    ]
    args << "--disable-pidwait" if OS.mac?

    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", *args, *std_configure_args
    system "make", "src/watch"
    bin.install "src/watch"
    man1.install "man/watch.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/watch --version")

    require "pty"
    output = []
    PTY.spawn("#{bin}/watch --errexit --chgexit --interval 1 date") do |r, w, pid|
      r.winsize = [24, 160]
      begin
        r.each_char { |char| output << char }
      rescue Errno::EIO
        # GNU/Linux raises EIO when read is done on closed pty
      end
    ensure
      r.close
      w.close
      Process.wait(pid)
    end
    assert_match "Every 1.0s: date", output.join
  end
end
