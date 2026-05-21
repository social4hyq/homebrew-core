class Aptly < Formula
  desc "Swiss army knife for Debian repository management"
  homepage "https://www.aptly.info/"
  url "https://github.com/aptly-dev/aptly/archive/refs/tags/v1.6.2.tar.gz"
  sha256 "cadfabda2a59f397adfe6f9ce3c9ddc6fe4c6052f0e03a300ba1f22d7cf0e09a"
  license "MIT"
  head "https://github.com/aptly-dev/aptly.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "830839fc9b22d127d420920e7e7bd27795ee4b34dad995841bd953e690ec91fd"
  end

  depends_on "go" => :build

  def install
    system "go", "generate"
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=#{version}")

    bash_completion.install "completion.d/aptly"
    zsh_completion.install "completion.d/_aptly"

    man1.install "man/aptly.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/aptly version")

    (testpath/".aptly.conf").write("{}")
    result = shell_output("#{bin}/aptly -config='#{testpath}/.aptly.conf' mirror list")
    assert_match "No mirrors found, create one with", result
  end
end
