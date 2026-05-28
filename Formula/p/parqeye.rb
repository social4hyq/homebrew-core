class Parqeye < Formula
  desc "Peek inside Parquet files right from your terminal"
  homepage "https://github.com/kaushiksrini/parqeye"
  url "https://github.com/kaushiksrini/parqeye/archive/refs/tags/v0.0.2.tar.gz"
  sha256 "67f896a9fe53a9f85022bdaf2042ae196feb784d2073df7d25eb37648d620139"
  license "MIT"
  head "https://github.com/kaushiksrini/parqeye.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9bfc15508b5e0e9f5753281ff8b4423b8843a9338b269d0fb026518a67b59bd5"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/parqeye --version")

    (testpath/"test.parquet").write <<~PARQUET
      PAR1
    PARQUET

    cmd = "#{bin}/parqeye #{testpath}/test.parquet 2>&1"
    output = if OS.mac?
      shell_output(cmd, 1)
    else
      require "pty"
      r, _w, pid = PTY.spawn(cmd)
      Process.wait(pid)
      r.read_nonblock(1024)
    end
    assert_match "EOF: Parquet file too small. Size is 5 but need 8", output
  end
end
