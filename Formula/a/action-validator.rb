class ActionValidator < Formula
  desc "Tool to validate GitHub Action and Workflow YAML files"
  homepage "https://github.com/mpalmer/action-validator"
  # Using crates.io source as it includes schemastore submodule code
  url "https://static.crates.io/crates/action-validator/action-validator-0.9.0.crate"
  sha256 "e379b5be9a8a4659aaec855a3321e40d98c5216d6191bc362a24d5b605a2cbcb"
  license "GPL-3.0-only"
  head "https://github.com/mpalmer/action-validator.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1a2501c6ffbed5f737516c9f1b54028c6d54e210b923a1aa09350440fe2ea091"
  end

  depends_on "rust" => :build

  def install
    ENV["GEN_DIR"] = buildpath
    system "cargo", "install", *std_cargo_args
  end

  test do
    test_action = testpath/"action.yml"
    test_action.write <<~YAML
      name: "Brew Test Action"
      description: "Test Action"
      inputs:
        test:
          description: "test input"
          default: "brew"
      runs:
        using: "node20"
        main: "index.js"
    YAML

    test_workflow = testpath/"workflow.yml"
    test_workflow.write <<~YAML
      name: "Brew Test Workflow"
      on: [push111]
      jobs:
        build:
          runs-on: ubuntu-latest
          steps:
            - uses: actions/checkout@v4
    YAML

    output = shell_output("#{bin}/action-validator --verbose #{test_action}")
    assert_match "Treating action.yml as an Action definition", output

    output = shell_output("#{bin}/action-validator --verbose #{test_workflow} 2>&1", 1)
    assert_match "Fatal error validating #{test_workflow}", output
    assert_match "Type of the value is wrong", output
  end
end
