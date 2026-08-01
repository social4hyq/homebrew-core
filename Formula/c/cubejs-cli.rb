class CubejsCli < Formula
  desc "Cube.js command-line interface"
  homepage "https://cube.dev/"
  url "https://registry.npmjs.org/cubejs-cli/-/cubejs-cli-1.7.16.tgz"
  sha256 "860c4a3449e2c6923e553c37927a4fc72f4eb278156dc583a4dc7061713758da"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "801fbf1b2c65eaa355420922286103564e010e30d88482b0da1111bf1c76db3b"
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
