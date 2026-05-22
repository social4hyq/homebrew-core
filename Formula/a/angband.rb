class Angband < Formula
  desc "Dungeon exploration game"
  homepage "https://rephial.org/"
  url "https://github.com/angband/angband/releases/download/4.2.6/Angband-4.2.6.tar.gz"
  sha256 "8c0ffa2b85d74bd0cc273752f61c0440dba93323cd790be460f90c8dced7cbf4"
  license "GPL-2.0-only"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0e0419065a288e905fb3cfb1cee0f0647e58827cdc7930d89abba79effc3fd45"
  end

  head do
    url "https://github.com/angband/angband.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  uses_from_macos "ncurses"

  def install
    args = %W[
      --bindir=#{bin}
      --enable-release
      --enable-curses
      --disable-ncursestest
      --disable-sdltest
      --disable-x11
    ]
    if OS.mac?
      sdk = MacOS.sdk_for_formula(self).path
      ENV["NCURSES_CONFIG"] = "#{sdk}/usr/bin/ncurses5.4-config"
      args << "--with-ncurses-prefix=#{sdk}/usr"

      # ncurse5.4-config is broken on recent macOS and will return nonexistent -lncursesw
      if MacOS.version >= :sonoma
        (buildpath/"brew").install_symlink sdk/"usr/lib/libncurses.tbd" => "libncursesw.tbd"
        ENV.append "LDFLAGS", "-L#{buildpath}/brew"
      end
    end
    system "./autogen.sh" if build.head?
    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    require "expect"
    require "pty"

    timeout = 10
    args = %W[
      -duser=#{testpath}
      -darchive=#{testpath}/archive
      -dpanic=#{testpath}/panic
      -dsave=#{testpath}/save
      -dscores=#{testpath}/scores
    ]

    PTY.spawn({ "LC_ALL" => "en_US.UTF-8", "TERM" => "xterm" }, bin/"angband", *args) do |r, w, pid|
      refute_nil r.expect("[Initialization complete]", timeout), "Expected initialization message"
      w.write "\x18"
      refute_nil r.expect("Please select your character", timeout), "Expected character selection"
      w.write "\x18"
      r.read
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    ensure
      r.close
      w.close
      Process.wait(pid)
    end
  end
end
