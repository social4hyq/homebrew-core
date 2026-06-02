class Vile < Formula
  desc "Vi Like Emacs Editor"
  homepage "https://invisible-island.net/vile/"
  url "https://invisible-island.net/archives/vile/current/vile-9.8zb.tgz"
  sha256 "d6239e6b728fa9d0b49f526d8f0998d2db4b7a7dfc317273dbff7aea2a09ea31"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://invisible-island.net/archives/vile/current/"
    regex(/href=.*?vile[._-]v?(\d+(?:\.\d+)+[a-z]*)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "851fbfb1dbb27dc7f076c1dae4457d935cb443c52c877f35cf16c47ed56e7da7"
  end

  uses_from_macos "flex" => :build
  uses_from_macos "libxcrypt"
  uses_from_macos "ncurses"
  uses_from_macos "perl"

  def install
    system "./configure", "--disable-imake",
                          "--enable-colored-menus",
                          "--with-ncurses",
                          "--without-x",
                          "--with-screen=ncurses",
                          *std_configure_args
    system "make", "install"
  end

  test do
    require "pty"
    ENV["TERM"] = "xterm"
    PTY.spawn(bin/"vile") do |r, w, _pid|
      w.write "ibrew\e:w new\r:q\r"
      r.read
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    end
    assert_path_exists testpath/"new"
    assert_equal "brew\n", (testpath/"new").read
  end
end
