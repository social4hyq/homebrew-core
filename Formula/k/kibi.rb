class Kibi < Formula
  desc "Text editor in ≤1024 lines of code, written in Rust"
  homepage "https://github.com/ilai-deutel/kibi"
  url "https://github.com/ilai-deutel/kibi/archive/refs/tags/v0.3.3.tar.gz"
  sha256 "a7a7b6f6937f39ae86fd4f556034a3744bb99091c102bc6f38b281ee751d10e9"
  license any_of: ["Apache-2.0", "MIT"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e0f5ef9726b828791d3a8849e99dc2955ac08a3d4df79b70592c7c70d361cf8b"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    PTY.spawn(bin/"kibi", "test.txt") do |r, w, _pid|
      r.winsize = [80, 43]
      sleep 1
      w.write "test data"
      sleep 1
      w.write "\u0013" # Ctrl + S
      sleep 1
      w.write "\u0011" # Ctrl + Q
      sleep 1
      begin
        r.read
      rescue Errno::EIO
        # GNU/Linux raises EIO when read is done on closed pty
      end
    end

    sleep 1
    assert_match "test data", (testpath/"test.txt").read
  end
end
