class BrunoCli < Formula
  desc "CLI of the open-source IDE For exploring and testing APIs"
  homepage "https://www.usebruno.com/"
  url "https://registry.npmjs.org/@usebruno/cli/-/cli-4.0.0.tgz"
  sha256 "f3eee310c779436b2a1b8b6f018775eca8b1c8483fac136a15f474e8b647f225"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "94267dd4d96e3aac5a1c7232cc12391c02241d65f587a49e98a04a7194b50ee9"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    # supress `punycode` module deprecation warning, upstream issue: https://github.com/usebruno/bruno/issues/2229
    (bin/"bru").write_env_script libexec/"bin/bru", NODE_OPTIONS: "--no-deprecation"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bru --version")
    assert_match "You can run only at the root of a collection", shell_output("#{bin}/bru run 2>&1", 4)
  end
end
