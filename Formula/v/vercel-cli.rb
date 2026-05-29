class VercelCli < Formula
  desc "Command-line interface for Vercel"
  homepage "https://vercel.com/home"
  url "https://registry.npmjs.org/vercel/-/vercel-54.5.1.tgz"
  sha256 "dbfb525ba81826fa896f2bb51c3dadf7d5477c2068a83db280a0cc759024505e"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cb6774d18e6c35693cd0ddd0c2a32c098e8e7e40265107b7bbab37f9a817e44a"
  end

  depends_on "node"

  def install
    inreplace "dist/index.js", "await getUpdateCommand()",
                               '"brew upgrade vercel-cli"'

    system "npm", "install", *std_npm_args
    node_modules = libexec/"lib/node_modules/vercel/node_modules"

    rm_r node_modules/"sandbox/dist/pty-server-linux-x86_64"

    deuniversalize_machos node_modules/"fsevents/fsevents.node" if OS.mac?
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    system bin/"vercel", "init", "jekyll"
    assert_path_exists testpath/"jekyll/_config.yml", "_config.yml must exist"
    assert_path_exists testpath/"jekyll/README.md", "README.md must exist"
  end
end
