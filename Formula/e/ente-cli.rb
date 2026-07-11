class EnteCli < Formula
  desc "Utility for exporting data from Ente and decrypt the export from Ente Auth"
  homepage "https://github.com/ente-io/"
  url "https://github.com/ente-io/ente/archive/refs/tags/cli-v0.3.0.tar.gz"
  sha256 "bcc7620943ed8e3b16f5f2295ab8ff2e7dfe0f9b60abc9f95bf2139a02f27708"
  license "AGPL-3.0-only"
  head "https://github.com/ente-io/ente.git", branch: "main"

  livecheck do
    url :stable
    regex(/^cli-v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "33c490eeb4e63676ecaffba8d870d50b21da43196fbda91b815599fd3bb832e9"
  end

  depends_on "go" => :build

  def install
    cd "cli" do
      system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"ente"), "main.go"
    end
  end

  test do
    if OS.linux?
      assert_match "Please mount a volume to /cli-data/", shell_output("#{bin}/ente version 2>&1", 1)
    else
      assert_match version.to_s, shell_output("#{bin}/ente version")
    end
  end
end
