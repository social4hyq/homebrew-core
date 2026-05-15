class Stepci < Formula
  desc "API Testing and Monitoring made simple"
  homepage "https://stepci.com"
  url "https://registry.npmjs.org/stepci/-/stepci-2.8.2.tgz"
  sha256 "0ba4ed74a5f51414b0ed86651e37a1b5e6af4e027187bedfc94dbd2176793178"
  license "MPL-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1e1d8a5542f242913d2f54fb27b6178aaece3f0a5fd630027994f9098f933f2a"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")
  end

  test do
    # https://docs.stepci.com/legal/privacy.html
    ENV["STEPCI_DISABLE_ANALYTICS"] = "1"

    (testpath/"workflow.yml").write <<~YAML
      version: "1.1"
      name: Status Check
      env:
        host: example.com
      tests:
        example:
          steps:
            - name: GET request
              http:
                url: https://${{env.host}}
                method: GET
                check:
                  status: /^20/
    YAML

    expected = <<~EOS
      Tests: 0 failed, 1 passed, 1 total
      Steps: 0 failed, 0 skipped, 1 passed, 1 total
    EOS
    assert_match expected, shell_output("#{bin}/stepci run workflow.yml")

    assert_match version.to_s, shell_output("#{bin}/stepci --version")
  end
end
