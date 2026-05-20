class StaticWebAppsCli < Formula
  desc "SWA CLI serves as a local development tool for Azure Static Web Apps"
  homepage "https://azure.github.io/static-web-apps-cli/"
  url "https://registry.npmjs.org/@azure/static-web-apps-cli/-/static-web-apps-cli-2.0.9.tgz"
  sha256 "37a84f7df8934a507aa8bdacde6bbe4565d794b2951d5760da99d89cb6348871"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "534c4f54e57ab73b8a6bcc403cc96dbc941a348b2c8e5d92dd5f2673f5f5fa35"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/swa --version")

    system bin/"swa", "init", "--yes"
    assert_path_exists testpath/"swa-cli.config.json"

    token = shell_output("#{bin}/swa deploy --print-token -dr")
    assert_match "undefined", token
    assert_match "Deploying to environment: preview", token
    assert_match testpath.to_s, token
  end
end
