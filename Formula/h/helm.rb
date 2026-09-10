class Helm < Formula
  desc "Kubernetes package manager"
  homepage "https://helm.sh/"
  url "https://github.com/helm/helm.git",
      tag:      "v4.3.0",
      revision: "bec5b06ed841fe5269972d864d5177944fd5970f"
  license "Apache-2.0"
  revision 1
  head "https://github.com/helm/helm.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d38265e4cba30ff02cc5de349eb590b6780dbc82218c7264a98a880eb4a6c46c"
  end

  depends_on "go" => :build

  def install
    system "make", "build"
    bin.install "bin/helm"

    mkdir "man1" do
      system bin/"helm", "docs", "--type", "man"
      man1.install Dir["*"]
    end

    generate_completions_from_executable(bin/"helm", shell_parameter_format: :cobra)
  end

  test do
    system bin/"helm", "create", "foo"
    assert File.directory? testpath/"foo/charts"

    version_output = shell_output("#{bin}/helm version 2>&1")
    assert_match "GitCommit:\"#{stable.specs[:revision]}\"", version_output
    assert_match "Version:\"v#{version}\"", version_output
  end
end
