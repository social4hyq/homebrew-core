class StructurizrCli < Formula
  desc "Command-line utility for Structurizr"
  homepage "https://docs.structurizr.com/cli"
  url "https://github.com/structurizr/cli/releases/download/v2025.11.09/structurizr-cli.zip"
  sha256 "f5365a463fc44d539ed19bec00c48ba1e1ecda0ccfd1ba40d2e7472d264eb79a"
  license "Apache-2.0"
  revision 1

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2dc885b38c338cf6eaa453c33adb4810bb45aa3eec9364d611e093323d4dcec9"
  end

  deprecate! date: "2026-02-17", because: :repo_archived
  disable! date: "2027-02-17", because: :repo_archived, replacement_formula: "structurizr"

  depends_on "openjdk"

  def install
    rm(Dir["*.bat"])
    libexec.install Dir["*"]
    (bin/"structurizr-cli").write_env_script libexec/"structurizr.sh", Language::Java.overridable_java_home_env
  end

  test do
    result = shell_output("#{bin}/structurizr-cli validate -w /dev/null", 1)
    assert_match "/dev/null is not a JSON or DSL file", result

    assert_match "structurizr-cli: #{version}", shell_output("#{bin}/structurizr-cli version")
  end
end
