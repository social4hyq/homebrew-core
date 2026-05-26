class Terraformer < Formula
  desc "CLI tool to generate terraform files from existing infrastructure"
  homepage "https://github.com/GoogleCloudPlatform/terraformer"
  url "https://github.com/GoogleCloudPlatform/terraformer/archive/refs/tags/0.8.30.tar.gz"
  sha256 "9e4738fadae011e458fa6fee168f47166cd3a9f5d7a9378018116345b0d6b4e6"
  license "Apache-2.0"
  head "https://github.com/GoogleCloudPlatform/terraformer.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "78b41680c1df2ad51af773509559f23609e8ba385d862419aabfb8379004ce00"
  end

  depends_on "go" => :build

  def install
    ldflags = %w[-s -w]
    # Work around failure: ld: B/BL out of range -162045188 (max +/-128MB)
    ldflags << "-extldflags=-ld_classic" if DevelopmentTools.clang_build_version == 1500 && Hardware::CPU.arm?

    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s,
      shell_output("#{bin}/terraformer version")

    assert_match "Available Commands",
      shell_output("#{bin}/terraformer -h")

    assert_match "aaa",
      shell_output("#{bin}/terraformer import google --resources=gcs --projects=aaa 2>&1", 1)
  end
end
