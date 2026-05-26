class Webpod < Formula
  desc "Deploy websites and apps anywhere"
  homepage "https://webpod.dev"
  url "https://registry.npmjs.org/webpod/-/webpod-1.0.0.tgz"
  sha256 "99b123e8d9f49b06d2dd0b886b81d2c2c64e510ba50eac2ba229e60b36719a7e"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3f1f761f991ee0ab62ad90b8b469f63cd59a49d5579a88fb37a455912d3ffa50"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/webpod --version")

    status_output = shell_output("#{bin}/webpod fakehost 2>&1", 1)
    assert_match "Webpod cannot connect to root@fakehost", status_output
  end
end
