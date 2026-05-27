class Blades < Formula
  desc "Blazing fast dead simple static site generator"
  homepage "https://www.getblades.org/"
  url "https://github.com/grego/blades/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "6bcce947580243e83a9bf4d6ec4afbc7e6cd0c7541a16d904c7d4f1314036bd0"
  license "GPL-3.0-or-later"
  head "https://github.com/grego/blades.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "82e5668cec6b4a399c3d8acb1b0cdb9c3e5a212fc7a40334bfb3ed12dc107090"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/blades version")

    require "expect"
    require "pty"

    timeout = 5
    PTY.spawn(bin/"blades", "init") do |r, w, pid|
      refute_nil r.expect("Name:", timeout), "Expected name input"
      w.write "brew\r"
      refute_nil r.expect("Author:", timeout), "Expected author input"
      w.write "test\r"
      w.write "Y\r" # `Start with a minimal working template?`
      Process.wait pid
    end

    assert_path_exists testpath/"content"
    assert_match "title = \"brew\"", (testpath/"Blades.toml").read
  end
end
