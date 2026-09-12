class Hawkeye < Formula
  desc "Simple license header checker and formatter, in multiple distribution forms"
  homepage "https://github.com/korandoru/hawkeye"
  url "https://github.com/korandoru/hawkeye/archive/refs/tags/v7.2.0.tar.gz"
  sha256 "d85bc32c3813040a83c72555998f74ca1e7218b6908faf1106d29af279e61e51"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cd66fa1219b4534538895dbba2e92df8f369dbdd2de8b21f3202523a481f9dae"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "hawkeye")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hawkeye --version")

    configfile = testpath/"licenserc.toml"
    configfile.write <<~TOML
      includes = ["licenserc.toml"]
    TOML

    assert_match "unknown field `includes`", shell_output("#{bin}/hawkeye format 2>&1", 2)
  end
end
