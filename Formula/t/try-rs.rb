class TryRs < Formula
  desc "Temporary workspace manager for fast experimentation in the terminal"
  homepage "https://try-rs.org/"
  url "https://github.com/tassiovirginio/try-rs/archive/refs/tags/v1.7.10.tar.gz"
  sha256 "f7080db6ffa9d84f222ea45e9e9327742605eb21dcdbc6349e564a165a5a0844"
  license "MIT"
  head "https://github.com/tassiovirginio/try-rs.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1378b620a67fb6a57893ccff9fdea5f0f9388161e601845c4d70a0e179078e00"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/try-rs --version")
    assert_match "command try-rs", shell_output("#{bin}/try-rs --setup-stdout zsh")
  end
end
