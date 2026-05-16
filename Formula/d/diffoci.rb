class Diffoci < Formula
  desc "Diff for Docker and OCI container images"
  homepage "https://github.com/reproducible-containers/diffoci"
  url "https://github.com/reproducible-containers/diffoci/archive/refs/tags/v0.1.8.tar.gz"
  sha256 "05fd59d8c6bb5d960077638a3e68725093b73c4ca9f2f2fe2da1f696020ee5d4"
  license "Apache-2.0"
  head "https://github.com/reproducible-containers/diffoci.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aeeebb45b302df48d2ff3e938f27db8f1d189fcd04f9493f09e6ede833a48df9"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/reproducible-containers/diffoci/cmd/diffoci/version.Version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/diffoci"

    generate_completions_from_executable(bin/"diffoci", shell_parameter_format: :cobra)
  end

  test do
    assert_match "Backend: local", shell_output("#{bin}/diffoci info")

    assert_match version.to_s, shell_output("#{bin}/diffoci --version")
  end
end
