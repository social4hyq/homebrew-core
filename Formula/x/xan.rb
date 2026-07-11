class Xan < Formula
  desc "CSV CLI magician written in Rust"
  homepage "https://github.com/medialab/xan"
  url "https://github.com/medialab/xan/archive/refs/tags/0.60.0.tar.gz"
  sha256 "eec65a0467fd58a8049648ed4bb93f12fd63da6f0ee55de11f785148638eeeab"
  license any_of: ["MIT", "Unlicense"]
  head "https://github.com/medialab/xan.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "90cc77d217d726305a72f73ebab648ec600ef17797b522df3b1fc06ee2bf78bf"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(features: "parquet")
  end

  test do
    (testpath/"test.csv").write("first header,second header")
    system bin/"xan", "stats", "test.csv"
    assert_match version.to_s, shell_output("#{bin}/xan --version").chomp
  end
end
