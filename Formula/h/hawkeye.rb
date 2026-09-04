class Hawkeye < Formula
  desc "Simple license header checker and formatter, in multiple distribution forms"
  homepage "https://github.com/korandoru/hawkeye"
  url "https://github.com/korandoru/hawkeye/archive/refs/tags/v7.0.1.tar.gz"
  sha256 "7a6af78223142af97da040362be4e3b26c89fab19d5aa3a5fdfe68d43a469588"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "594dd3e71810c4271785cd797c1378c155f53dc156925fc6b6cd843e1816eb32"
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
