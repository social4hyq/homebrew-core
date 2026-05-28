class Define < Formula
  desc "Command-line dictionary (thesaurus) app, with access to multiple sources"
  homepage "https://github.com/Rican7/define"
  url "https://github.com/Rican7/define/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "b8f0a83bbf345330d1081634e3b865527d4924be8e771501283abf17c4304514"
  license "MIT"
  head "https://github.com/Rican7/define.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "105fdb811c55ef3dcccb7ba222ff814324eb8045585435ae1e801d1310ca759b"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/Rican7/define/internal/version.identifier=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match "Free Dictionary API", shell_output("#{bin}/define --list-sources")

    output = shell_output("#{bin}/define -s FreeDictionaryAPI homebrew")
    assert_match "A beer brewed by enthusiasts rather than commercially", output

    assert_match "define #{version}", shell_output("#{bin}/define --version")
  end
end
