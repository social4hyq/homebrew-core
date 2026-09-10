class Xsv < Formula
  desc "Fast CSV toolkit written in Rust"
  homepage "https://github.com/BurntSushi/xsv"
  url "https://github.com/BurntSushi/xsv/archive/refs/tags/0.13.0.tar.gz"
  sha256 "2b75309b764c9f2f3fdc1dd31eeea5a74498f7da21ae757b3ffd6fd537ec5345"
  license any_of: ["MIT", "Unlicense"]
  revision 1
  head "https://github.com/BurntSushi/xsv.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "24cf954a7427a0ce4dea6f514f5f648d80aa85b7190c2bd82b6b72ed21a50301"
  end

  deprecate! date: "2025-04-27", because: :repo_archived
  disable! date: "2026-04-27", because: :repo_archived

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"test.csv").write("first header,second header")
    system bin/"xsv", "stats", "test.csv"
  end
end
