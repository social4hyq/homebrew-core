class Ratchet < Formula
  desc "Tool for securing CI/CD workflows with version pinning"
  homepage "https://github.com/sethvargo/ratchet"
  url "https://github.com/sethvargo/ratchet/archive/refs/tags/v0.12.0.tar.gz"
  sha256 "7fe2adcf0f5eea0fdd80812d4a0bb20e0b7a4197b6c448191338214d94a8b594"
  license "Apache-2.0"
  head "https://github.com/sethvargo/ratchet.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "da40b1b5ff715f65fa3f175dab3f1a74804dda8be09534de88724e582798e998"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s
      -w
      -X=github.com/sethvargo/ratchet/internal/version.version=#{version}
      -X=github.com/sethvargo/ratchet/internal/version.commit=#{tap.user}
    ]
    system "go", "build", *std_go_args(ldflags:)

    pkgshare.install "testdata"
  end

  test do
    cp_r pkgshare/"testdata", testpath
    output = shell_output("#{bin}/ratchet check testdata/github.yml 2>&1", 1)
    assert_match "found 5 unpinned refs", output

    output = shell_output("#{bin}/ratchet -v 2>&1")
    assert_match "ratchet #{version}", output
  end
end
