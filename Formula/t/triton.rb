class Triton < Formula
  desc "Joyent Triton CLI"
  homepage "https://www.npmjs.com/package/triton"
  url "https://registry.npmjs.org/triton/-/triton-7.18.0.tgz"
  sha256 "dfbecc0a7ff8ba4ebc3fccabe0db0457e135f4a03e04e653b2e415118ce0d823"
  license "MPL-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "26148789b49ce4f3c1e32f105a54ef0e4a53c3cbca93517937cd6b2b8c9dc67c"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
    generate_completions_from_executable(bin/"triton", "completion", shells: [:bash])
  end

  test do
    output = shell_output("#{bin}/triton profile ls")
    assert_match(/\ANAME  CURR  ACCOUNT  USER  URL$/, output)
  end
end
