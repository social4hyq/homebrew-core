class SourceToImage < Formula
  desc "Tool for building source and injecting into docker images"
  homepage "https://github.com/openshift/source-to-image"
  url "https://github.com/openshift/source-to-image.git",
      tag:      "v1.6.2",
      revision: "038c647b1a9046569c07e6159641786a67a990fc"
  license "Apache-2.0"
  head "https://github.com/openshift/source-to-image.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "58bb67cd5b7699c1bab286d4be94ee954b467bfb7b02c78d2652f0f65cc692ec"
  end

  depends_on "go" => :build

  def install
    system "hack/build-go.sh"
    arch = Hardware::CPU.intel? ? "amd64" : Hardware::CPU.arch.to_s
    bin.install "_output/local/bin/#{OS.kernel_name.downcase}/#{arch}/s2i"

    generate_completions_from_executable(bin/"s2i", "completion", shells: [:bash, :zsh])
  end

  test do
    system bin/"s2i", "create", "testimage", testpath
    assert_path_exists testpath/"Dockerfile", "s2i did not create the files."
  end
end
