class EslintD < Formula
  desc "Speed up eslint to accelerate your development workflow"
  homepage "https://github.com/mantoni/eslint_d.js"
  url "https://registry.npmjs.org/eslint_d/-/eslint_d-15.0.3.tgz"
  sha256 "2d635c2a6037f2840cfb07804b729555222bfaa642dfbd1d3823447ece593e85"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8a335a723f00d26d70652fa78347fe8e9a5aa197b6ec2a22162eb2ebe1e6931b"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  service do
    run [opt_bin/"eslint_d", "start"]
    keep_alive true
    working_dir var/"eslint_d"
    log_path var/"log/eslint_d.log"
    error_log_path var/"log/eslint_d.err.log"
  end

  test do
    output = shell_output("#{bin}/eslint_d status")
    assert_match "eslint_d: Not running", output

    assert_match version.to_s, shell_output("#{bin}/eslint_d --version")
  end
end
