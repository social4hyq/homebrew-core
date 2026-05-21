class Lux < Formula
  desc "Fast and simple video downloader"
  homepage "https://github.com/iawia002/lux"
  url "https://github.com/iawia002/lux/archive/refs/tags/v0.24.1.tar.gz"
  sha256 "69d4fe58c588cc6957b8682795210cd8154170ac51af83520c6b1334901c6d3d"
  license "MIT"
  head "https://github.com/iawia002/lux.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7870590ddc5aa6e570643adc5f8f8f1e6561ffdbd4a0b4abc6c0332205646a2b"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/iawia002/lux/app.version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    system bin/"lux", "-i", "https://upload.wikimedia.org/wikipedia/commons/c/c2/GitHub_Invertocat_Logo.svg"
  end
end
