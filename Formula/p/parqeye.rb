class Parqeye < Formula
  desc "Peek inside Parquet files right from your terminal"
  homepage "https://github.com/kaushiksrini/parqeye"
  url "https://github.com/kaushiksrini/parqeye/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "2b8bc834d91594a708d2eea47f0e9ed2fe79b79dca1e9cad631d20b563a612c3"
  license "MIT"
  head "https://github.com/kaushiksrini/parqeye.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ec39931044e4425adde49fec0decfc8f1b7a53f76705ed07093d97e39ccdb1b3"
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
