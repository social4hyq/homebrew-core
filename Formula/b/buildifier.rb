class Buildifier < Formula
  desc "Format bazel BUILD files with a standard convention"
  homepage "https://github.com/bazelbuild/buildtools"
  url "https://github.com/bazelbuild/buildtools/archive/refs/tags/v8.5.1.tar.gz"
  sha256 "f3b800e9f6ca60bdef3709440f393348f7c18a29f30814288a7326285c80aab9"
  license "Apache-2.0"
  head "https://github.com/bazelbuild/buildtools.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0490d8f39305839191f1a4c66e284e9f4361303922596be5257dbd53d19488a9"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./buildifier"
  end

  test do
    touch testpath/"BUILD"
    system bin/"buildifier", "-mode=check", "BUILD"
  end
end
