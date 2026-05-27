class Sgn < Formula
  desc "Shikata ga nai (仕方がない) encoder ported into go with several improvements"
  homepage "https://github.com/EgeBalci/sgn"
  url "https://github.com/EgeBalci/sgn/archive/refs/tags/v2.0.2.tar.gz"
  sha256 "eb5d5636e7fa701e646fd321cd47adb0ded8650af1532315ddd493aff06c4c22"
  license "MIT"
  head "https://github.com/EgeBalci/sgn.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e658412e5061958fa54b37ad8b9466f9b124f36eee199970b4980df82347b8dd"
  end

  depends_on "go" => :build
  depends_on "keystone"

  def install
    ENV["CGO_ENABLED"] = "1" if OS.linux?
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/EgeBalci/sgn/config.Version=#{version}")
  end

  test do
    output = shell_output("#{bin}/sgn -i #{test_fixtures("mach/a.out")} -o #{testpath}/sgn.out")
    assert_match "All done ＼(＾O＾)／", output
  end
end
