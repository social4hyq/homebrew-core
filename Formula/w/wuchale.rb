class Wuchale < Formula
  desc "Protobuf-like i18n from plain code"
  homepage "https://wuchale.dev/"
  url "https://registry.npmjs.org/wuchale/-/wuchale-0.26.3.tgz"
  sha256 "8d80b024a0f7ae2441c07ad449dcaf143032e6ec51398d43eb764b9528ce2116"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d6406b79079eedf6d45838e5509c9a44bb81aee50697e990e062bb1370e1c98b"
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
