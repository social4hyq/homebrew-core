class Aiac < Formula
  desc "Artificial Intelligence Infrastructure-as-Code Generator"
  homepage "https://github.com/gofireflyio/aiac"
  url "https://github.com/gofireflyio/aiac/archive/refs/tags/v5.3.0.tar.gz"
  sha256 "45e48cd8958d835b402e0e68d7aa8b9642deb535464dad5d6b83fb8f8ed3d79e"
  license "Apache-2.0"
  head "https://github.com/gofireflyio/aiac.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3036df3f7e527fa8999ab2a8cd7727b2514aee1ede8d4eb9858e9fe8db50e092"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/gofireflyio/aiac/v#{version.major}/libaiac.Version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/aiac --version")
    assert_match "failed loading configuration", shell_output("#{bin}/aiac python print hello world 2>&1", 1)
  end
end
