class Scilla < Formula
  desc "DNS, subdomain, port, directory enumeration tool"
  homepage "https://github.com/edoardottt/scilla"
  url "https://github.com/edoardottt/scilla/archive/refs/tags/v1.3.3.tar.gz"
  sha256 "d3d767422c371bdbeda0f674f658b22b538c5dbc88ae4b449d8bfcb351b734d4"
  license "GPL-3.0-or-later"
  head "https://github.com/edoardottt/scilla.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ac4afd77dee99e58c4ba38271d4156e92bb0d2341685392db7603960aefa3d1c"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/scilla"
  end

  test do
    output = shell_output("#{bin}/scilla dns -target brew.sh")
    assert_match <<~EOS, output
      =====================================================
      target: brew.sh
      ================ SCANNING DNS =======================
    EOS

    assert_match version.to_s, shell_output("#{bin}/scilla --help 2>&1", 1)
  end
end
