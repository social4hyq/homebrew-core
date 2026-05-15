class Nom < Formula
  desc "RSS reader for the terminal"
  homepage "https://github.com/guyfedwards/nom"
  url "https://github.com/guyfedwards/nom/archive/refs/tags/v3.3.0.tar.gz"
  sha256 "27e33b618e223d433a99161b3e401958a510cd5a4298ed77a6553c2a42d59d70"
  license "GPL-3.0-only"
  head "https://github.com/guyfedwards/nom.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d78716ab1dbf93ae488500ede7879c4fe5efd745a87d44196771f44ed182897f"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "1" # Required by `go-sqlite3`

    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/nom"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nom version")

    assert_match "configpath", shell_output("#{bin}/nom config")
  end
end
