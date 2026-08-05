class Appwrite < Formula
  desc "Command-line tool for Appwrite"
  homepage "https://appwrite.io"
  url "https://registry.npmjs.org/appwrite-cli/-/appwrite-cli-25.1.0.tgz"
  sha256 "8305396001127824ee21cb3b4922ef5c17f3fefdc2e7807fbf50b751c5c4bc43"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1f35b61c53569ae7d61cfbe6e7d432639511eabcfe5d4e5c2d093c319831fc04"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    node_modules = libexec/"lib/node_modules/appwrite-cli/node_modules"
    machos = %w[fsevents/fsevents.node app-path/main]
    machos.each { |macho| deuniversalize_machos node_modules/macho } if OS.mac?
  end

  test do
    output = shell_output("#{bin}/appwrite client --endpoint http://localhost/v1 2>&1", 1)
    assert_match "Error: Invalid endpoint", output

    assert_match version.to_s, shell_output("#{bin}/appwrite --version")
  end
end
