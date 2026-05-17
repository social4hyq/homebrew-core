class Levant < Formula
  desc "Templating and deployment tool for HashiCorp Nomad jobs"
  homepage "https://github.com/hashicorp/levant"
  url "https://github.com/hashicorp/levant/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "8d299e890af5a3c6e9048f930b10cd34276656142358c298497ec5d7d8efa263"
  license "MPL-2.0"
  head "https://github.com/hashicorp/levant.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4d406e5e6388783e60bdaacbf54148b4aadbd2c06a0dfa12c98565631bd115f6"
  end

  deprecate! date: "2025-06-27", because: :repo_archived
  disable! date: "2026-06-27", because: :repo_archived, replacement_formula: "nomad-pack"

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/hashicorp/levant/version.Version=#{version}
      -X github.com/hashicorp/levant/version.VersionPrerelease=#{tap.user}
    ]

    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    (testpath/"template.nomad").write <<~HCL
      resources {
          cpu    = [[.resources.cpu]]
          memory = [[.resources.memory]]
      }
    HCL

    (testpath/"variables.json").write <<~JSON
      {
        "resources":{
          "cpu":250,
          "memory":512,
          "network":{
            "mbits":10
          }
        }
      }
    JSON

    assert_match "resources {\n    cpu    = 250\n    memory = 512\n}\n",
      shell_output("#{bin}/levant render -var-file=#{testpath}/variables.json #{testpath}/template.nomad")

    assert_match "Levant v#{version}-#{tap.user}", shell_output("#{bin}/levant --version")
  end
end
