class Openskills < Formula
  desc "Universal skills loader for AI coding agents"
  homepage "https://github.com/numman-ali/openskills"
  url "https://registry.npmjs.org/openskills/-/openskills-1.5.0.tgz"
  sha256 "2aa0c31c2a09fad8c32705d519a5497aa671381189bde9d8f7911a7967a9d9bc"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f176f3db4cd5708d52fa7bdbb335ca490cfbcc3604021f3e015e1b12fe8b7297"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/openskills --version")
    assert_match "No skills installed", shell_output("#{bin}/openskills list")
  end
end
