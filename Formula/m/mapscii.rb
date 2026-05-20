class Mapscii < Formula
  desc "Whole World In Your Console"
  homepage "https://github.com/rastapasta/mapscii"
  url "https://registry.npmjs.org/mapscii/-/mapscii-0.3.1.tgz"
  sha256 "21f18b687975f1decef998664ef6d292cf2379d9e4308a5b4cbb66af240341b3"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cf7e87400def36aaf0de54f997a420487051bbcaab9cb65772b5b6e61f9bbcb7"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    output_log = testpath/"output.log"
    pid = spawn bin/"mapscii", [:out, :err] => output_log.to_s
    sleep 5
    sleep 10 if OS.mac? && Hardware::CPU.intel?
    assert_match "Failed to start MapSCII", output_log.read
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
