class Multica < Formula
  desc "CLI and local daemon for the Multica AI agent workspace"
  homepage "https://multica.ai"
  url "https://github.com/multica-ai/multica/archive/refs/tags/v0.8.1.tar.gz"
  sha256 "4d142f4d676f90576dcf71787d3b9d20f6ec5329e0f3a8db14364cdc90253ad2"
  license :cannot_represent # Multica License (Apache-2.0 plus additional conditions)

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "go" => :build

  def install
    cd "server" do
      ENV["CGO_ENABLED"] = "0"
      system "go", "build", *std_go_args(output: bin/"multica", ldflags: "-s -w -X main.version=#{version}"),
             "./cmd/multica"
    end
  end

  test do
    ENV["HOME"] = testpath/"home"
    assert_match "multica #{version}", shell_output("#{bin}/multica --version")
    assert_match "CORE COMMANDS", shell_output("#{bin}/multica --help")
  end
end
