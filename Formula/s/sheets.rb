class Sheets < Formula
  desc "Terminal based spreadsheet tool"
  homepage "https://github.com/maaslalani/sheets"
  url "https://github.com/maaslalani/sheets/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "d65b37c4d40c0a531a87a81848350528387e1247b24d2aa3a04dd5a41338c9fa"
  license "MIT"
  head "https://github.com/maaslalani/sheets.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d44058ee8b21356b7a201e386d7f802e70c1f516ec3ebf0df1f239de89310ca5"
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
