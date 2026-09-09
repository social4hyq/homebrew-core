class Hawkeye < Formula
  desc "Simple license header checker and formatter, in multiple distribution forms"
  homepage "https://github.com/korandoru/hawkeye"
  url "https://github.com/korandoru/hawkeye/archive/refs/tags/v7.1.0.tar.gz"
  sha256 "f74f5997a4d18595320a0d7aa63333268c9015000e93bfbd1aef7e74ea5769d1"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bac45a83a00e7e0945d7206640887076bdd6ab6ea4a897f2d8145f8dd3fd5728"
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
