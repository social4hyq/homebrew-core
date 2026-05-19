class OdoDev < Formula
  desc "Developer-focused CLI for Kubernetes and OpenShift"
  homepage "https://odo.dev"
  url "https://github.com/redhat-developer/odo.git",
      tag:      "v3.16.1",
      revision: "cd346c5e6c0d9891b06824915ed4e3281a4ecc02"
  license "Apache-2.0"
  head "https://github.com/redhat-developer/odo.git", branch: "main"

  # Upstream creates releases that use a stable tag (e.g., `v1.2.3`) but are
  # labeled as "pre-release" on GitHub before the version is released, so it's
  # necessary to use the `GithubLatest` strategy.
  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d9b4737caeb810cd081fa60aeb1d9f02535d42de041f4d640d38e240c8390ca3"
  end

  depends_on "go" => :build
  conflicts_with "odo", because: "odo also ships 'odo' binary"

  def install
    # Replace `-dirty` suffix in `--version` output with `-Homebrew`.
    inreplace "Makefile", "--dirty", "--dirty=-Homebrew"

    system "make", "bin"
    bin.install "odo"
  end

  test do
    # try set preference
    ENV["GLOBALODOCONFIG"] = "#{testpath}/preference.yaml"
    system bin/"odo", "preference", "set", "ConsentTelemetry", "false"
    system bin/"odo", "preference", "add", "registry", "StagingRegistry", "https://registry.stage.devfile.io"
    assert_path_exists testpath/"preference.yaml"

    # test version
    version_output = shell_output("#{bin}/odo version --client 2>&1").strip
    assert_match version.to_s, version_output

    # try to create a new component
    system bin/"odo", "init", "--devfile", "nodejs", "--name", "test", "--devfile-registry", "StagingRegistry"
    assert_path_exists testpath/"devfile.yaml"

    dev_output = shell_output("#{bin}/odo dev 2>&1", 1).strip
    assert_match "✗  unable to access the cluster", dev_output
  end
end
