class Wuchale < Formula
  desc "Protobuf-like i18n from plain code"
  homepage "https://wuchale.dev/"
  url "https://registry.npmjs.org/wuchale/-/wuchale-0.25.8.tgz"
  sha256 "8d4190b07d6ddbeb0de6e7f5b4aa37fd4f0c657fa356d1071d798ee9ed36d388"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "75f741f582996b3c1687b67159b3d7e773e50cbced8a80ca8a0daf4c4126606c"
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
