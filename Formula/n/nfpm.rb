class Nfpm < Formula
  desc "Simple deb and rpm packager"
  homepage "https://nfpm.goreleaser.com/"
  url "https://github.com/goreleaser/nfpm/archive/refs/tags/v2.47.0.tar.gz"
  sha256 "906b8dde0c5626376779f3ebddea3554b0eb6e1b8450a09bdc746cba92ef5dea"
  license "MIT"
  head "https://github.com/goreleaser/nfpm.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "56bf13485cc0745ff84f8fa8ec0213806e8492347b990165e898e70d7551926e"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=v#{version}"), "./cmd/nfpm"

    generate_completions_from_executable(bin/"nfpm", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nfpm --version 2>&1")

    system bin/"nfpm", "init"
    assert_match "This is an example nfpm configuration file", File.read(testpath/"nfpm.yaml")

    # remove the generated default one
    # and use stubbed one for another test
    File.delete(testpath/"nfpm.yaml")
    (testpath/"nfpm.yaml").write <<~YAML
      name: "foo"
      arch: "amd64"
      platform: "linux"
      version: "v1.0.0"
      section: "default"
      priority: "extra"
    YAML

    system bin/"nfpm", "pkg", "--packager", "deb", "--target", "."
    assert_path_exists testpath/"foo_1.0.0_amd64.deb"
  end
end
