class Prettierd < Formula
  desc "Prettier daemon"
  homepage "https://github.com/fsouza/prettierd"
  url "https://registry.npmjs.org/@fsouza/prettierd/-/prettierd-0.28.0.tgz"
  sha256 "944799736015578fdff5ba50dcf200eb052bec3cddfaf922c938867962d6b04a"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ec2d6be281f939a0b61733e340861a7db0207dbb3ec0e67bc95c9ec9ed46e752"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    output = pipe_output("#{bin}/prettierd test.js", "const arr = [1,2];", 0)
    assert_equal "const arr = [1, 2];", output.chomp
  end
end
