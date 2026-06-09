class Edgevpn < Formula
  desc "Immutable, decentralized, statically built p2p VPN"
  homepage "https://mudler.github.io/edgevpn"
  url "https://github.com/mudler/edgevpn/archive/refs/tags/v0.35.2.tar.gz"
  sha256 "2e2e43d7129b0e3630b0dcb21c25c7fdccc2a3e2aca3f9f46e21c8037476ddd3"
  license "Apache-2.0"
  head "https://github.com/mudler/edgevpn.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "120d98d3b83d630b2f4a779798c1eace5531aafb4b6297cd509e917b6471bce9"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/mudler/edgevpn/internal.Version=#{version}
    ]

    ENV["CGO_ENABLED"] = "0"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    generate_token_output = pipe_output("#{bin}/edgevpn -g")
    assert_match "otp:", generate_token_output
    assert_match "max_message_size: 20971520", generate_token_output
  end
end
