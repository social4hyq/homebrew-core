class EnpassCli < Formula
  desc "Enpass command-line client"
  homepage "https://github.com/hazcod/enpass-cli"
  url "https://github.com/hazcod/enpass-cli/archive/refs/tags/v1.11.0.tar.gz"
  sha256 "a211566965a4737d41ca5473d096df996a63ce53e45c22957db816f6d4b57ec4"
  license "MIT"
  head "https://github.com/hazcod/enpass-cli.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "352a4c16448beb6af3ec949d4c16636727378d9cf9ed6cd6a143194363d928f0"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "1"
    system "go", "build", *std_go_args(ldflags: "-s -w -X 'main.version=#{version}'"), "./cmd/enpasscli"
    pkgshare.install "test/vault.json", "test/vault.enpassdb"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/enpass-cli version 2>&1")

    # Get test vault files
    mkdir "testvault"
    cp [pkgshare/"vault.json", pkgshare/"vault.enpassdb"], "testvault"
    # Master password for test vault
    ENV["MASTERPW"] = "absolutely-No-clue"
    # Retrieve password for "johndoe" from test vault
    assert_match "noIdeaata11", shell_output("#{bin}/enpass-cli -vault testvault/ pass johndoe").chomp
  end
end
