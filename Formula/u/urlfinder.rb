class Urlfinder < Formula
  desc "Extracting URLs and subdomains from JS files on a website"
  homepage "https://github.com/pingc0y/URLFinder"
  url "https://github.com/pingc0y/URLFinder/archive/refs/tags/2023.9.9.tar.gz"
  sha256 "033944c58814547d240182daf8506bdf6cd0cd54b25a57212a87e2e70ec92bc7"
  license "MIT"
  head "https://github.com/pingc0y/URLFinder.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3a6af34de885d1b7659667feba09cc1c571b70d6503458e003436a03a39e9c75"
  end

  depends_on "go" => :build

  # upstream PR ref, https://github.com/pingc0y/URLFinder/pull/96
  patch do
    url "https://github.com/pingc0y/URLFinder/commit/cd4b141bd92448ed4b27a1db65b05075e40e8200.patch?full_index=1"
    sha256 "e08f45c1a103125dfbaec04305f26140fe6766aa137b7a5fbe899d18efdb1064"
  end

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match "Start 1 Spider...", shell_output("#{bin}/urlfinder -u https://example.com")
    assert_match version.to_s, shell_output("#{bin}/urlfinder version")
  end
end
