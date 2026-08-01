class Timoni < Formula
  desc "Package manager for Kubernetes, powered by CUE and inspired by Helm"
  homepage "https://timoni.sh/"
  url "https://github.com/stefanprodan/timoni/archive/refs/tags/v0.28.0.tar.gz"
  sha256 "7952da3ef6b3d8df4ee596550e638afa9a5c41962a794eb9650f33c0f48e8244"
  license "Apache-2.0"
  head "https://github.com/stefanprodan/timoni.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "57f82249eea0a56d55d7480e325325645273be8ce1b0eb01865fdfee7b9acc0a"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.VERSION=#{version}"), "./cmd/timoni"

    generate_completions_from_executable(bin/"timoni", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/timoni version")

    system bin/"timoni", "mod", "init", "test-mod", "--namespace", "test"
    assert_path_exists testpath/"test-mod/timoni.cue"
    assert_path_exists testpath/"test-mod/values.cue"

    output = shell_output("#{bin}/timoni mod vet test-mod 2>&1")
    assert_match "INF timoni.sh/test-mod valid module", output
  end
end
