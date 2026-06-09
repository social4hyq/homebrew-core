class Crossplane < Formula
  desc "Build control planes without needing to write code"
  homepage "https://github.com/crossplane/cli"
  url "https://github.com/crossplane/cli/archive/refs/tags/v2.3.2.tar.gz"
  sha256 "dcafe7e43a2aa718b4c766754800cedf0ce5b7d8df9f6b013f26d24414460e71"
  license "Apache-2.0"
  head "https://github.com/crossplane/cli.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5e5be400a059c23d1512c44aafa6b4c73a267360c83ae0d49c0d577c4401ee66"
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
