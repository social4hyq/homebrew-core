class Bombadillo < Formula
  desc "Non-web browser, designed for a growing list of protocols"
  homepage "https://bombadillo.colorfield.space/"
  url "https://ftp.debian.org/debian/pool/main/b/bombadillo/bombadillo_2.4.0.orig.tar.gz"
  sha256 "d52a753e7a77c5ab486f536a7c488e61c68a8c11a5e455143d281b3d8306afa0"
  license "GPL-3.0-or-later"
  head "https://tildegit.org/sloum/bombadillo.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "20f8431cd801897a53aad7153e15f96bc3816700eb9be56c0522b6120747ebd4"
  end

  depends_on "go" => :build

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    require "pty"
    require "io/console"

    cmd = "#{bin}/bombadillo gopher://bombadillo.colorfield.space"
    r, w, pid = PTY.spawn({ "XDG_CONFIG_HOME" => testpath/".config" }, cmd)
    r.winsize = [80, 43]
    sleep 1
    w.write "q"
    output = ""
    begin
      r.each_line { |line| output += line }
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    end
    assert_match "Bombadillo is a non-web browser", output

    status = PTY.check(pid)
    refute_nil status
    assert status.success?
  end
end
