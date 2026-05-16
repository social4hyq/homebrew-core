class RevealMd < Formula
  desc "Get beautiful reveal.js presentations from your Markdown files"
  homepage "https://github.com/webpro/reveal-md"
  url "https://registry.npmjs.org/reveal-md/-/reveal-md-6.1.4.tgz"
  sha256 "699d44c19f8437f294464ca457d35ad779e6f605299a38ea293b7aa75363d6f9"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "408105e50b81e323636bcb29acc2f0e183325d8378825994ba936c37a9f805de"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    # Remove incompatible pre-built `bare-fs`/`bare-os`/`bare-url` binaries
    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    node_modules = libexec/"lib/node_modules/reveal-md/node_modules"
    node_modules.glob("{bare-fs,bare-os,bare-url}/prebuilds/*")
                .each { |dir| rm_r(dir) if dir.basename.to_s != "#{os}-#{arch}" }
  end

  test do
    (testpath/"test.md").write("# Hello, Reveal-md!")

    output_log = testpath/"output.log"
    pid = spawn bin/"reveal-md", testpath/"test.md", [:out, :err] => output_log.to_s
    sleep 8
    sleep 8 if OS.mac? && Hardware::CPU.intel?
    assert_match "Serving reveal.js", output_log.read

    assert_match version.to_s, shell_output("#{bin}/reveal-md --version")
  ensure
    Process.kill("TERM", pid)
    Process.wait(pid)
  end
end
