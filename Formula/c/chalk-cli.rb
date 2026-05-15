class ChalkCli < Formula
  desc "Terminal string styling done right"
  homepage "https://github.com/chalk/chalk-cli"
  url "https://registry.npmjs.org/chalk-cli/-/chalk-cli-6.0.0.tgz"
  sha256 "480a85e48da024092e1b63fe260f810880f5f82322d82f62304f32e970112216"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "90af2224fad5c53035063339e0b3b07520624174a32e31a8ac4084e15d1e46a6"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match "hello, world!", pipe_output("#{bin}/chalk bold cyan --stdin", "hello, world!")
  end
end
