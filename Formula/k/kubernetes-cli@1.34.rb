class KubernetesCliAT134 < Formula
  desc "Kubernetes command-line interface"
  homepage "https://kubernetes.io/docs/reference/kubectl/"
  url "https://github.com/kubernetes/kubernetes.git",
      tag:      "v1.34.11",
      revision: "3a634765b787dd069f7f714fa77d767cb7d43795"
  license "Apache-2.0"

  livecheck do
    url :stable
    regex(/^v?(1\.34(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e00d449cb29e84df604fa6f0600960ad3865698e705d3bca21a11e91b333970b"
  end

  keg_only :versioned_formula

  # https://kubernetes.io/releases/patch-releases/#1-34
  disable! date: "2026-10-27", because: :deprecated_upstream

  depends_on "go" => :build

  uses_from_macos "rsync" => :build

  on_macos do
    depends_on "bash" => :build
    depends_on "coreutils" => :build
  end

  def install
    ENV.prepend_path "PATH", Formula["coreutils"].libexec/"gnubin" if OS.mac? # needs GNU date
    ENV["FORCE_HOST_GO"] = "1"
    system "make", "WHAT=cmd/kubectl"
    bin.install "_output/bin/kubectl"

    generate_completions_from_executable(bin/"kubectl", shell_parameter_format: :cobra)

    # Install man pages
    # Leave this step for the end as this dirties the git tree
    system "hack/update-generated-docs.sh"
    man1.install Dir["docs/man/man1/*.1"]
  end

  test do
    run_output = shell_output("#{bin}/kubectl 2>&1")
    assert_match "kubectl controls the Kubernetes cluster manager.", run_output

    version_output = shell_output("#{bin}/kubectl version --client --output=yaml 2>&1")
    assert_match "gitTreeState: clean", version_output
    assert_match stable.specs[:revision].to_s, version_output
  end
end
