class Dockviz < Formula
  desc "Visualizing docker data"
  homepage "https://github.com/justone/dockviz"
  url "https://github.com/justone/dockviz/archive/refs/tags/v0.6.4.tar.gz"
  sha256 "228e2c11fad1de38ec63e5d46e60bf9411625447c3c381dd0cd99aaa05d4e5db"
  license "Apache-2.0"
  head "https://github.com/justone/dockviz.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9ae3cdfb6c8a0564909eb05c9f0b443e64cea60a5b489062b71d88fa00f82bc1"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dockviz --version")
  end
end
