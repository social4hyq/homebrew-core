class Hcledit < Formula
  desc "Command-line editor for HCL"
  homepage "https://github.com/minamijoyo/hcledit"
  url "https://github.com/minamijoyo/hcledit/archive/refs/tags/v0.2.18.tar.gz"
  sha256 "40be8406251263e90006853bcd336dc27b09fae93c56840dc3a44c3fd72f968c"
  license "MIT"
  head "https://github.com/minamijoyo/hcledit.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a1928c3dc69d036ef63bc712a6b25ee8ccce84e095aadd5732a750470524177a"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/minamijoyo/hcledit/cmd.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hcledit version")

    (testpath/"test.hcl").write <<~HCL
      resource "foo" "bar" {
        attr1 = "val1"
        nested {
          attr2 = "val2"
        }
      }
    HCL

    output = pipe_output("#{bin}/hcledit attribute get resource.foo.bar.attr1",
                        (testpath/"test.hcl").read, 0)
    assert_equal "\"val1\"", output.chomp
  end
end
