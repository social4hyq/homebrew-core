class Toktop < Formula
  desc "LLM usage monitor in terminal"
  homepage "https://github.com/htin1/toktop"
  url "https://github.com/htin1/toktop/archive/refs/tags/v0.1.5.tar.gz"
  sha256 "9e01566757971e7cf42dd881ea9e8a8a53bbda4dade210a3c80df71638418ee4"
  license "MIT"
  head "https://github.com/htin1/toktop.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7c81fbd1a6d59bda26e138e04ace4617688a60ab650644126a4ad63491f1cafa"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    ENV["OPENAI_ADMIN_KEY"] = "test"
    ENV["ANTHROPIC_ADMIN_KEY"] = "test"
    assert_match "OpenAI", if OS.mac?
      pipe_output("#{bin}/toktop 2>&1", "\e", 1)
    else
      require "pty"
      r, w, pid = PTY.spawn("#{bin}/toktop 2>&1")
      r.winsize = [80, 43]
      w.write "q\nq"
      Process.wait(pid)
      r.read_nonblock(4096)
    end
  end
end
