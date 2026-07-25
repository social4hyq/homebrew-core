class Crossplane < Formula
  desc "Build control planes without needing to write code"
  homepage "https://github.com/crossplane/cli"
  url "https://github.com/crossplane/cli/archive/refs/tags/v2.4.1.tar.gz"
  sha256 "065237cd2d8da289804abde5d4a74bfedb84fb39df83d28a5843da5aa8dde69d"
  license "Apache-2.0"
  head "https://github.com/crossplane/cli.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2bf75b26d5cd190563f6f7dc566ebb8f57cab6f4525ab02ebc4825d9aee4b197"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/crossplane/crossplane-runtime/v#{version.major}/pkg/version.version=v#{version}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/crossplane"
  end

  test do
    assert_match "Client Version: v#{version}", shell_output("#{bin}/crossplane version --client")

    (testpath/"composition.yaml").write <<~YAML
      apiVersion: apiextensions.crossplane.io/v1
      kind: Composition
      metadata:
        name: example
      spec:
        compositeTypeRef:
          apiVersion: example.org/v1alpha1
          kind: XExample
        mode: Pipeline
        pipeline:
          - step: example
            functionRef:
              name: example-function
    YAML

    output = shell_output("#{bin}/crossplane composition convert composition-environment " \
                          "composition.yaml -o converted.yaml 2>&1")
    assert_match "No changes needed", output
  end
end
