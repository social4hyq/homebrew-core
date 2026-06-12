class Helm < Formula
  desc "Kubernetes package manager"
  homepage "https://helm.sh/"
  url "https://github.com/helm/helm.git",
      tag:      "v4.2.1",
      revision: "d591a19b953bd9cfdf7d9ddd83c2f4ffdaeafb29"
  license "Apache-2.0"
  head "https://github.com/helm/helm.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b234c6e6f1ef23ae41735009b86fa126446f7e03cdb9f038c8fe257a4fd34545"
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
