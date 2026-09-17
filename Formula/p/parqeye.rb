class Parqeye < Formula
  desc "Peek inside Parquet files right from your terminal"
  homepage "https://github.com/kaushiksrini/parqeye"
  url "https://github.com/kaushiksrini/parqeye/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "142fb53d92be4f65888cd463b2bae52d0aa23fab12aad2fbb2ae059f69b9978d"
  license "MIT"
  head "https://github.com/kaushiksrini/parqeye.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f172ed2f89b06079b25a5147da1c29bc14b85d6c87cef76b15a69f6e2ade938b"
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
