class Wails < Formula
  desc "Create beautiful applications using Go"
  homepage "https://wails.io"
  url "https://github.com/wailsapp/wails/archive/refs/tags/v2.15.0.tar.gz"
  sha256 "4c865cbd5ab81401cf4557e54dfe517efc90d29980ccdaa54178b426fdd6d4a3"
  license "MIT"
  revision 1
  head "https://github.com/wailsapp/wails.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f3d49f9702e227c3d69434c9ccf8401deeb78fb69bee59035f477f2162280434"
  end

  depends_on "go"

  def install
    # The top-level go.work only lists v3, so disable workspace mode to build v2.
    ENV["GOWORK"] = "off"
    cd "v2" do
      system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/wails"
    end
  end

  test do
    ENV["NO_COLOR"] = "1"

    output = shell_output("#{bin}/wails init -n brewtest 2>&1")
    assert_match "# Initialising Project 'brewtest'", output
    assert_match "Template          | Vanilla + Vite", output

    assert_path_exists testpath/"brewtest/go.mod"
    assert_equal "brewtest", JSON.parse((testpath/"brewtest/wails.json").read)["name"]

    assert_match version.to_s, shell_output("#{bin}/wails version")
  end
end
