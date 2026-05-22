class GraphqlCli < Formula
  desc "Command-line tool for common GraphQL development workflows"
  homepage "https://github.com/Urigo/graphql-cli"
  url "https://registry.npmjs.org/graphql-cli/-/graphql-cli-4.1.0.tgz"
  sha256 "c52d62ac108d4a3f711dbead0939bd02e3e2d0c82f8480fd76fc28f285602f5c"
  license "MIT"

  # The Npm page is nearly 2 MB compressed (due to there being thousands
  # of pre-release versions of the package) and livecheck can time out, so we
  # check the Git tags in this instance.
  livecheck do
    url :homepage
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f495bb03e7e5b833349e38e19bf86c0874059a0e7f74dd9c619f9bd6dfc3d2c2"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    require "expect"
    require "open3"

    Open3.popen2(bin/"graphql", "init") do |stdin, stdout, wait_thread|
      stdout.expect "Select the best option for you"
      stdin.write "1\n"
      stdout.expect "? What is the name of the project?"
      stdin.write "brew\n"
      stdout.expect "? Choose a template to bootstrap"
      stdin.write "1\n"
      wait_thread.join
    end

    assert_path_exists testpath/"brew"
    assert_match "Graphback runtime template with Apollo Server and PostgreSQL", (testpath/"brew/package.json").read
  end
end
