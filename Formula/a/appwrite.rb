class Appwrite < Formula
  desc "Command-line tool for Appwrite"
  homepage "https://appwrite.io"
  url "https://registry.npmjs.org/appwrite-cli/-/appwrite-cli-21.0.1.tgz"
  sha256 "af79417d56ecdcc9bad6d7a805c2a967e013d04f38a3a95681b95994135e2d16"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "39babc688aac03ec1cef54ef74ed73ba1a13ab30b87ba6565d3e0543abba5894"
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
