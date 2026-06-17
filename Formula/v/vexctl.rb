class Vexctl < Formula
  desc "Tool to create, transform and attest VEX metadata"
  homepage "https://openssf.org/projects/openvex/"
  url "https://github.com/openvex/vexctl/archive/refs/tags/v0.4.4.tar.gz"
  sha256 "c846b1288f837ebcbebef7817ec450e5b0a4b3d8f7b176717ae6f3198539d991"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "22a84896650c2232812a9ba46b9a076c64a4586dbfa6b0866837484ea81b9654"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X sigs.k8s.io/release-utils/version.gitVersion=#{version}
      -X sigs.k8s.io/release-utils/version.gitCommit=#{tap.user}
      -X sigs.k8s.io/release-utils/version.gitTreeState=clean
      -X sigs.k8s.io/release-utils/version.buildDate=#{time.iso8601}
    ]

    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"vexctl", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/vexctl version")

    assert_match "Valid Statuses:\n\tnot_affected\n\taffected\n\tfixed\n\tunder_investigation\n",
    shell_output("#{bin}/vexctl list status")
  end
end
