class FirebaseCli < Formula
  desc "Firebase command-line tools"
  homepage "https://firebase.google.com/docs/cli/"
  url "https://registry.npmjs.org/firebase-tools/-/firebase-tools-15.20.0.tgz"
  sha256 "95e89a94cb143361183e5836c428ae999fc046df16c4ff12203e80b2bcfb1f38"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a35ebec7d1d5a6a432e039bc1078b03a7c5738dd4be9a849be1c5b9d98658748"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    node_modules = libexec/"lib/node_modules/firebase-tools/node_modules"
    deuniversalize_machos node_modules/"fsevents/fsevents.node" if OS.mac?

    # Remove incompatible pre-built `bare-fs`/`bare-os`/`bare-url` binaries
    os = OS.kernel_name.downcase
    arch = Hardware::CPU.intel? ? "x64" : Hardware::CPU.arch.to_s
    node_modules.glob("{bare-fs,bare-os,bare-url}/prebuilds/*")
                .each { |dir| rm_r(dir) if dir.basename.to_s != "#{os}-#{arch}" }
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/firebase --version")

    assert_match "Failed to authenticate", shell_output("#{bin}/firebase projects:list", 1)
  end
end
