class Plakar < Formula
  desc "Create backups with compression, encryption and deduplication"
  homepage "https://plakar.io"
  url "https://github.com/PlakarKorp/plakar/archive/refs/tags/v1.0.6.tar.gz"
  sha256 "5f9af49e9957b2fc659f0c9192db748785c95a1319290e69469df971fe3eeb9e"
  license "ISC"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "87c0bd36cc1cbb9ee2b33f6b815595b43a2e3081eed4f2fa8b2ed91bb5017a9e"
  end

  depends_on "go" => :build

  # bump cockroachdb/swiss for Go 1.26 support, upstream pr ref, https://github.com/PlakarKorp/plakar/pull/1845
  patch do
    url "https://github.com/PlakarKorp/plakar/commit/79c5ce3cf30822010e395d33078b6abc6a0b992a.patch?full_index=1"
    sha256 "37df26982c016c3eefb1103db63622cffe65a8b79e114a3c5201b236276317fc"
  end

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/plakar version")

    repo = testpath/"plakar"
    system bin/"plakar", "-no-agent", "at", repo, "create", "-plaintext", "-no-compression"
    assert_path_exists repo
    assert_match "Repository", shell_output("#{bin}/plakar -no-agent at #{repo} info")
  end
end
