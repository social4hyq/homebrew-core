class Goawk < Formula
  desc "POSIX-compliant AWK interpreter written in Go"
  homepage "https://benhoyt.com/writings/goawk/"
  url "https://github.com/benhoyt/goawk/archive/refs/tags/v1.32.0.tar.gz"
  sha256 "5425248c199bf506987af0deff9109bbdeecfb723f11b30c712c54a10b78f1a9"
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
