class Sleek < Formula
  desc "CLI tool for formatting SQL"
  homepage "https://github.com/nrempel/sleek"
  url "https://github.com/nrempel/sleek/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "fcb589fdc5ece8c050883ff0b56aec6bd25e2e4d6e77a1d52e870535d66fdf67"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ad55505e9d2c91f9fcce95d6ba824e2f7d00daf4ee96f2d93975fb31be39be5e"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sleek --version")

    (testpath/"test.sql").write <<~SQL
      SELECT * from foo WHERE bar = 'quux';
    SQL
    system bin/"sleek", testpath/"test.sql"
  end
end
