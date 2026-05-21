class Sheets < Formula
  desc "Terminal based spreadsheet tool"
  homepage "https://github.com/maaslalani/sheets"
  url "https://github.com/maaslalani/sheets/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "e33563769858abba1812d6f9e1f427241a9a5c65da3a34a87d8784c8a050e25e"
  license "MIT"
  head "https://github.com/maaslalani/sheets.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f8482c4a1700d5b7652f588d75558dcd614456275a1470075564638cee37c5c9"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    (testpath/"test.csv").write <<~CSV
      Name,Age,City
      Alice,30,NYC
      Bob,25,LA
    CSV

    assert_equal "30", shell_output("#{bin}/sheets #{testpath}/test.csv B2").strip
    assert_equal "Alice\nBob", shell_output("#{bin}/sheets #{testpath}/test.csv A2:A3").strip
  end
end
