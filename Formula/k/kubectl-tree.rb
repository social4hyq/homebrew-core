class KubectlTree < Formula
  desc "Kubectl plugin to browse Kubernetes object hierarchies as a tree"
  homepage "https://github.com/ahmetb/kubectl-tree"
  url "https://github.com/ahmetb/kubectl-tree/archive/refs/tags/v0.6.0.tar.gz"
  sha256 "a2c62e887be6bd66c920edb26f9e8ad40d483d4d257e31641fbbef8f0ab1a6ce"
  license "Apache-2.0"
  head "https://github.com/ahmetb/kubectl-tree.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cdb7a30b5f2c6040217d0ad921f89aabd73f4a69b6308db145a60a8008565794"
  end

  depends_on "go" => :build
  depends_on "kubernetes-cli"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/kubectl-tree"
  end

  test do
    output = shell_output("kubectl tree deployment -A 2>&1", 1)
    assert_match "couldn't get current server API group list", output
  end
end
