class Scarb < Formula
  desc "Cairo package manager"
  homepage "https://docs.swmansion.com/scarb/"
  url "https://github.com/software-mansion/scarb/archive/refs/tags/v2.18.0.tar.gz"
  sha256 "2c24f599173cc69bcf1350b49b5aa4b2f97b50355469f77e4e648b833601761d"
  license "MIT"
  head "https://github.com/software-mansion/scarb.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "320c057dffcc792cf7250e9ad4d2f1a2d63253d8cb974f464609e235cf0c0fab"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    %w[
      scarb
      extensions/scarb-cairo-language-server
      extensions/scarb-cairo-test
      extensions/scarb-doc
    ].each do |f|
      system "cargo", "install", *std_cargo_args(path: f)
    end

    generate_completions_from_executable(bin/"scarb", "completions", shell_parameter_format: :clap)
  end

  test do
    ENV["SCARB_INIT_TEST_RUNNER"] = "none"

    assert_match "#{testpath}/Scarb.toml", shell_output("#{bin}/scarb manifest-path")

    system bin/"scarb", "init", "--name", "brewtest", "--no-vcs"
    assert_path_exists testpath/"src/lib.cairo"
    assert_match "brewtest", (testpath/"Scarb.toml").read

    assert_match version.to_s, shell_output("#{bin}/scarb --version")
    assert_match version.to_s, shell_output("#{bin}/scarb cairo-test --version")
    assert_match version.to_s, shell_output("#{bin}/scarb doc --version")
  end
end
