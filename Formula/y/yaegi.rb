class Yaegi < Formula
  desc "Yet another elegant Go interpreter"
  homepage "https://github.com/traefik/yaegi"
  url "https://github.com/traefik/yaegi/archive/refs/tags/v0.16.1.tar.gz"
  sha256 "872ceac063a8abfa71ecdeb56b1b960ca02abd5e9b6c926ae1bd3eb097cad44b"
  license "Apache-2.0"
  head "https://github.com/traefik/yaegi.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ed91fb64c3f8a364543cd680abf9d798ef6fb610e3779d4ab2965532e7b542bd"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X=main.version=#{version}"), "./cmd/yaegi"
  end

  test do
    assert_match "4", pipe_output(bin/"yaegi", "println(3 + 1)", 0)
  end
end
