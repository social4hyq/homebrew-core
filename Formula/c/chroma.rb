class Chroma < Formula
  desc "General purpose syntax highlighter in pure Go"
  homepage "https://github.com/alecthomas/chroma"
  url "https://github.com/alecthomas/chroma/archive/refs/tags/v2.25.0.tar.gz"
  sha256 "5bae5544762e9c58d1a6eb7b04248576859d866855561e82226020a8dda606a7"
  license "MIT"
  head "https://github.com/alecthomas/chroma.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8ad589cf64074928abf46f1212e944869117172e71f033c359664b4e42cc15dd"
  end

  depends_on "go" => :build

  def install
    cd "cmd/chroma" do
      system "go", "build", *std_go_args(ldflags: "-s -w")
    end
  end

  test do
    json_output = JSON.parse(shell_output("#{bin}/chroma --json #{test_fixtures("test.diff")}"))
    assert_equal "GenericHeading", json_output[0]["type"]
  end
end
