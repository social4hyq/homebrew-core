class Ijq < Formula
  desc "Interactive jq"
  homepage "https://codeberg.org/gpanders/ijq"
  url "https://codeberg.org/gpanders/ijq/archive/v1.3.0.tar.gz"
  sha256 "b65cf7f5285affe3ab9a1887d12e6c313f437b18a5cf2b52add6cfd7e76dd2c7"
  license "GPL-3.0-or-later"
  head "https://codeberg.org/gpanders/ijq.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8e00f51f26da9e42b4803a3064f3511a8121a22d4ac2cf72159b3ffe7a239089"
  end

  depends_on "go" => :build
  depends_on "scdoc" => :build

  uses_from_macos "jq", since: :sequoia

  def install
    system "make", "prefix=#{prefix}", "install"
  end

  test do
    ENV["TERM"] = "xterm"

    (testpath/"filterfile.jq").write '["foo", "bar", "baz"] | sort | add'

    require "expect"
    require "pty"
    PTY.spawn("#{bin}/ijq -H '' -M -n -f filterfile.jq > result") do |r, w, pid|
      refute_nil r.expect("barbazfoo", 5), "Expected barbazfoo"
      w.write "\r"
      r.read
    rescue Errno::EIO
      # GNU/Linux raises EIO when read is done on closed pty
    ensure
      r.close
      w.close
      Process.wait(pid)
    end
    assert_equal "\"barbazfoo\"\n", (testpath/"result").read
  end
end
