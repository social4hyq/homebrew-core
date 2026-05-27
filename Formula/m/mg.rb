class Mg < Formula
  desc "Small Emacs-like editor"
  homepage "https://github.com/ibara/mg"
  url "https://github.com/ibara/mg/releases/download/mg-7.3/mg-7.3.tar.gz"
  sha256 "1fd52feed9a96b93ef16c28ec4ff6cb25af85542ec949867bffaddee203d1e95"
  license all_of: [:public_domain, "ISC", "BSD-2-Clause", "BSD-3-Clause", "BSD-4-Clause"]
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4fc2a9a2cdf5d63a2ee4cf26ab54bfbfeb13fe743700893a3ccfa8ac56011253"
  end

  uses_from_macos "ncurses"

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--mandir=#{man}"
    system "make"
    system "make", "install"
  end

  test do
    require "pty"
    PTY.spawn({ "TERM" => "xterm" }, bin/"mg", "test") do |r, w, pid|
      sleep 1
      w.write "brew\n\u0018\u0003y"
      r.read
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    ensure
      r.close
      w.close
      Process.wait(pid)
    end
    assert_equal "brew\n", (testpath/"test").read
  end
end
