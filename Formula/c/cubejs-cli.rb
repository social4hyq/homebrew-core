class CubejsCli < Formula
  desc "Cube.js command-line interface"
  homepage "https://cube.dev/"
  url "https://registry.npmjs.org/cubejs-cli/-/cubejs-cli-1.6.56.tgz"
  sha256 "5800626982d6e3cfa059cfa64a37fa22d6d2e0a1296ec214c0c540d009a17753"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8d376967e32b1c705470d17d2033ab46d5ac9ee8231ccf4568872a76b8307308"
  end

  depends_on "node"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    node_modules = libexec/"lib/node_modules/cubejs-cli/node_modules"
    deuniversalize_machos node_modules/"fsevents/fsevents.node" if OS.mac?
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cubejs --version")
    system bin/"cubejs", "create", "hello-world", "-d", "postgres"
    assert_path_exists testpath/"hello-world/model/cubes/orders.yml"
  end
end
