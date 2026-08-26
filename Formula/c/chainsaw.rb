class Chainsaw < Formula
  desc "Rapidly Search and Hunt through Windows Forensic Artefacts"
  homepage "https://github.com/WithSecureLabs/chainsaw"
  url "https://github.com/WithSecureLabs/chainsaw/archive/refs/tags/v2.16.5.tar.gz"
  sha256 "fa376e837cc2ebb830a0d59d1e6ab2adf60a2a85b1c2c71594bc3f41d6810aee"
  license "GPL-3.0-only"
  head "https://github.com/WithSecureLabs/chainsaw.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1f3cd9447772a3565e8c3cbdd02c16d16dd9f7c43eea15b0579b9d0fce9d74b6"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    mkdir "chainsaw" do
      output = shell_output("#{bin}/chainsaw lint --kind chainsaw . 2>&1")
      assert_match "Validated 0 detection rules out of 0", output

      output = shell_output("#{bin}/chainsaw dump --json . 2>&1", 1)
      assert_match "Dumping the contents of forensic artefact", output
    end

    assert_match version.to_s, shell_output("#{bin}/chainsaw --version")
  end
end
