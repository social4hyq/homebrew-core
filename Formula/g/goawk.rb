class Goawk < Formula
  desc "POSIX-compliant AWK interpreter written in Go"
  homepage "https://benhoyt.com/writings/goawk/"
  url "https://github.com/benhoyt/goawk/archive/refs/tags/v1.31.0.tar.gz"
  sha256 "2df274d8680a9405646b0729b6465b8952f795f118358cf8a25fe1526cbd0909"
  license "MIT"
  head "https://github.com/benhoyt/goawk.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0b38ce2c6f7160478abc17dc8ef324682d2a7ce11b386e52ed5a61747071f295"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    output = pipe_output("#{bin}/goawk '{ gsub(/Macro/, \"Home\"); print }' -", "Macrobrew")
    assert_equal "Homebrew", output.strip
  end
end
