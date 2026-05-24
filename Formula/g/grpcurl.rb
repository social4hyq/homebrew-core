class Grpcurl < Formula
  desc "Like cURL, but for gRPC"
  homepage "https://github.com/fullstorydev/grpcurl"
  url "https://github.com/fullstorydev/grpcurl/archive/refs/tags/v1.9.3.tar.gz"
  sha256 "bb555087f279af156159c86d4d3d5dd3f2991129e4cd6b09114e6851a679340d"
  license "MIT"
  head "https://github.com/fullstorydev/grpcurl.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "580a98bc606f49670df2eba5c8241fd2ff962d2e842c5d216f210f0b9e296dfd"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/grpcurl"
  end

  test do
    (testpath/"test.proto").write <<~PROTO
      syntax = "proto3";
      package test;
      message HelloWorld {
        string hello_world = 1;
      }
    PROTO
    system bin/"grpcurl", "-msg-template", "-proto", "test.proto", "describe", "test.HelloWorld"
  end
end
