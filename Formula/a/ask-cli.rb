class AskCli < Formula
  desc "CLI tool for Alexa Skill Kit"
  homepage "https://github.com/alexa/ask-cli"
  url "https://registry.npmjs.org/ask-cli/-/ask-cli-2.30.7.tgz"
  sha256 "437b55f774064e053b0185956afc69ecb38a8b53c996a6e1e49960918b54f909"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "72ae718ea091d756a85984aa5591ff1459c4b93248b1200f55c5f7ddd623b826"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.write_exec_script libexec/"bin/ask"
  end

  test do
    output = shell_output("#{bin}/ask deploy 2>&1", 1)
    assert_match "File #{testpath}/.ask/cli_config not exists.", output
  end
end
