class Sherif < Formula
  desc "Opinionated, zero-config linter for JavaScript monorepos"
  homepage "https://github.com/QuiiBz/sherif"
  url "https://github.com/QuiiBz/sherif/archive/refs/tags/v1.11.1.tar.gz"
  sha256 "4069bb60326caf7d50d06d15e85e838707206f061319461867101046e4fe01b8"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d111a3e72757b86303fe7390c45786e3f93821129e5ad5d6b492685c0ca57a53"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"package.json").write <<~JSON
      {
        "name": "test",
        "version": "1.0.0",
        "private": true,
        "packageManager": "npm",
        "workspaces": [ "." ]
      }
    JSON
    (testpath/"test.js").write <<~JS
      console.log('Hello, world!');
    JS
    assert_match "No issues found", shell_output("#{bin}/sherif --no-install .")
  end
end
