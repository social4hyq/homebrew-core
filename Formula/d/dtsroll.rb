class Dtsroll < Formula
  desc "CLI tool for bundling TypeScript declaration files"
  homepage "https://github.com/privatenumber/dtsroll"
  url "https://registry.npmjs.org/dtsroll/-/dtsroll-1.8.2.tgz"
  sha256 "a40b1a0cf0fd28f7a2e0dfa69a6234ffd183bf2bb69108851f8a80b6f1d104a4"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "71e031b68ad852a9e44ac45996eb44c874fe01c1ebe078d7261c320a15004e99"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    node_modules = libexec/"lib/node_modules/dtsroll/node_modules"
    deuniversalize_machos node_modules/"fsevents/fsevents.node" if OS.mac?
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dtsroll --version")

    (testpath/"dts.d.ts").write "export type Foo = string;"

    assert_match "Entry points\n → dts.d.ts", shell_output("#{bin}/dtsroll dts.d.ts")
  end
end
