class NomadPack < Formula
  desc "Templating and packaging tool used with HashiCorp Nomad"
  homepage "https://github.com/hashicorp/nomad-pack"
  url "https://github.com/hashicorp/nomad-pack/archive/refs/tags/v0.4.2.tar.gz"
  sha256 "844a072ba9c9098d846899899a5603d3058290a2ecdc7dfd77cb3c9a9de9585e"
  license "MPL-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1d82aa62a5a21efefca54e66be8d020398cbdce2cd274d71d4fcc328eb88dffb"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/hashicorp/nomad-pack/internal/pkg/version.GitCommit=#{tap.user}
      -X github.com/hashicorp/nomad-pack/internal/pkg/version.GitDescribe=v#{version}
    ]

    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    (testpath/"metadata.hcl").write <<~HCL
      app {
        url = ""
      }
      pack {
        name        = "test"
        description = "Test"
        version     = "0.1.2"
      }
    HCL

    (testpath/"variables.hcl").write <<~HCL
      variable "cpu" {
        type    = number
        default = 500
      }
      variable "memory" {
        type    = number
        default = 256
      }
    HCL

    (testpath/"templates/test.nomad.tpl").write <<~HCL
      resources {
        cpu    = [[ var "cpu" . ]]
        memory = [[ var "memory" . ]]
      }
    HCL

    assert_match <<~HCL, shell_output("#{bin}/nomad-pack render .")
      resources {
        cpu    = 500
        memory = 256
      }
    HCL

    assert_match version.to_s, shell_output("#{bin}/nomad-pack version")
  end
end
