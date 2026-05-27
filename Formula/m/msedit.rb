class Msedit < Formula
  desc "Simple text editor with clickable interface"
  homepage "https://github.com/microsoft/edit"
  url "https://github.com/microsoft/edit/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "f35da309c5f3d92b10e5c4b2267e4d5e29d809b2aa460e80326b11f7feba72a5"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "163576a336460383168b065a4b237b5dbb4c54aa61a4e743f6f4baf3e6e3e425"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "pkgconf" => :build
  end

  def install
    ENV["RUSTC_BOOTSTRAP"] = "1"
    system "cargo", "install", *std_cargo_args(path: "crates/edit")
  end

  test do
    output_log = testpath/"output.log"
    pid = if OS.mac?
      spawn bin/"edit", "--version", [:out, :err] => output_log.to_s
    else
      require "pty"
      PTY.spawn("#{bin}/edit --version > #{output_log}").last
    end

    sleep 1
    assert_match version.to_s, output_log.read
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
