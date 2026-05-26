class Kubebuilder < Formula
  desc "SDK for building Kubernetes APIs using CRDs"
  homepage "https://github.com/kubernetes-sigs/kubebuilder"
  url "https://github.com/kubernetes-sigs/kubebuilder.git",
      tag:      "v4.14.0",
      revision: "505d63f3b272472b5556ff650f03ba64d885cf3a"
  license "Apache-2.0"
  head "https://github.com/kubernetes-sigs/kubebuilder.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "035e3a1fe0ee3cc384ee6f7edd6df7c7aaba94b36e13899fb3194af5f31a730d"
  end

  depends_on "go"

  def install
    goos = Utils.safe_popen_read("#{Formula["go"].bin}/go", "env", "GOOS").chomp
    goarch = Utils.safe_popen_read("#{Formula["go"].bin}/go", "env", "GOARCH").chomp

    ldflags = %W[
      -s -w
      -X sigs.k8s.io/kubebuilder/v4/cmd.kubeBuilderVersion=#{version}
      -X sigs.k8s.io/kubebuilder/v4/cmd.goos=#{goos}
      -X sigs.k8s.io/kubebuilder/v4/cmd.goarch=#{goarch}
      -X sigs.k8s.io/kubebuilder/v4/cmd.gitCommit=#{Utils.git_head}
      -X sigs.k8s.io/kubebuilder/v4/cmd.buildDate=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"kubebuilder", shell_parameter_format: :cobra)
  end

  test do
    mkdir "test" do
      system "go", "mod", "init", "example.com"
      system bin/"kubebuilder", "init",
                 "--plugins", "go.kubebuilder.io/v4",
                 "--project-version", "3",
                 "--skip-go-version-check"
    end

    assert_match <<~YAML, (testpath/"test/PROJECT").read
      domain: my.domain
      layout:
      - go.kubebuilder.io/v4
      projectName: test
      repo: example.com
      version: "3"
    YAML

    assert_match version.to_s, shell_output("#{bin}/kubebuilder version")
  end
end
