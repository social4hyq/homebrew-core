class Gitmoji < Formula
  desc "Interactive command-line tool for using emoji in commit messages"
  homepage "https://gitmoji.dev"
  url "https://registry.npmjs.org/gitmoji-cli/-/gitmoji-cli-9.7.0.tgz"
  sha256 "feafd3520f57f5eed9c1df0a603cbd4c69869daab5fd2011bd7e3711541f482b"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cdf62cee9855e70e7043388890ebeafd1cb5c50b099d212d0dad74df02d07b07"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    # Ensure we have uniform bottles.
    files = ["global-directory/index.d.ts", "npm-run-path/node_modules/path-key/index.d.ts",
             "path-key/index.d.ts", "xdg-basedir/index.d.ts", "xdg-basedir/index.js",
             "npm-run-path/index.d.ts", "global-directory/index.js", "@pnpm/npm-conf/lib/defaults.js"]
    files.each do |file|
      inreplace libexec/"lib/node_modules/gitmoji-cli/node_modules/#{file}", "/usr/local", HOMEBREW_PREFIX
    end
  end

  test do
    assert_match ":bug:", shell_output("#{bin}/gitmoji --search bug")
  end
end
