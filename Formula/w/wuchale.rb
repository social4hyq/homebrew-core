class Wuchale < Formula
  desc "Protobuf-like i18n from plain code"
  homepage "https://wuchale.dev/"
  url "https://registry.npmjs.org/wuchale/-/wuchale-0.24.2.tgz"
  sha256 "da78841d10e72b2d4c479b6c3b77f7c1aa92c4df47f0f6a6a7b63438b9bfa7fe"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2e5a5698fec35f826229e1607839da75c4b66f1fcd358d4d455fbf32c3ffa083"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    (testpath/"wuchale.config.mjs").write <<~EOS
      export default {
        locales: ["en"]
      };
    EOS

    output = shell_output("#{bin}/wuchale --config #{testpath}/wuchale.config.mjs status 2>&1", 1)
    assert_match "at least one adapter is needed.", output
  end
end
