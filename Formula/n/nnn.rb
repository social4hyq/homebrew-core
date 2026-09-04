class Nnn < Formula
  desc "Tiny, lightning fast, feature-packed file manager"
  homepage "https://github.com/jarun/nnn"
  url "https://github.com/jarun/nnn/archive/refs/tags/v5.3.tar.gz"
  sha256 "79ee69f3ced7c0778d207df76b4d4d680636975ccda002eeb19d0917fcba3d36"
  license "BSD-2-Clause"
  head "https://github.com/jarun/nnn.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "019c2eccfcca8f6ce1af73173c0ff06bfb5e2755c80972cea8604d4462614d77"
  end

  depends_on "gnu-sed"
  depends_on "ncurses"
  depends_on "readline"

  def install
    inreplace "src/nnn.c", "#include <fts.h>\n", ""
    inreplace "src/nnn.c",
              "#ifdef __linux__\n#ifndef __TERMUX__\n\t/* Pin thread to specific CPU core",
              "#ifdef __GLIBC__\n#ifndef __TERMUX__\n\t/* Pin thread to specific CPU core"
    system "make", "install", "PREFIX=#{prefix}"

    bash_completion.install "misc/auto-completion/bash/nnn-completion.bash" => "nnn"
    zsh_completion.install "misc/auto-completion/zsh/_nnn"
    fish_completion.install "misc/auto-completion/fish/nnn.fish"

    pkgshare.install "misc/quitcd"
  end

  test do
    # Testing this curses app requires a pty
    require "pty"

    # nnn 5.3 aborts if XDG_CONFIG_HOME is set but not an accessible directory
    ENV["XDG_CONFIG_HOME"] = testpath

    (testpath/"testdir").mkdir
    PTY.spawn(bin/"nnn", testpath/"testdir") do |r, w, pid|
      w.write "q"
      output = if OS.mac?
        r.read
      else
        Process.wait(pid)
        r.read_nonblock(4096)
      end
      assert_match "~/testdir", output
    end
  end
end
