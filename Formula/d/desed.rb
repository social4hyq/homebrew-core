class Desed < Formula
  desc "Debugger for Sed"
  homepage "https://soptik.tech/articles/building-desed-the-sed-debugger.html"
  url "https://github.com/SoptikHa2/desed/archive/refs/tags/v1.2.2.tar.gz"
  sha256 "73c75eaa65cccde5065a947e45daf1da889c054d0f3a3590d376d7090d4f651a"
  license "GPL-3.0-or-later"
  head "https://github.com/SoptikHa2/desed.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8f2977d1adacf9e17e078244b8d7612cb0326edda97582b1f04313fec49733a1"
  end

  depends_on "rust" => :build
  depends_on "gnu-sed" => :test

  def install
    system "cargo", "install", *std_cargo_args
    man1.install "desed.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/desed --version")
    # desed is a TUI application
    # Just test that it opens when files are provided
    assert_match "No such file or directory", shell_output("#{bin}/desed test.sed test.txt 2>&1")

    (testpath/"test.txt").write <<~EOS
      1 2 3 4 5 1 2 3 4 5
      232 1 4 526 2 1 1 5
    EOS
    (testpath/"test.sed").write <<~SED
      =
      :bbb
      s/1/2/
      t bbb
      H
      p
      G
      G
      p
    SED

    begin
      pid = spawn bin/"desed", testpath/"test.sed", testpath/"test.txt"
      sleep 2
    ensure
      Process.kill("SIGINT", pid)
      Process.wait(pid)
    end
  end
end
