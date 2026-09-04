class Checkpwn < Formula
  desc "Check Have I Been Pwned and see if it's time for you to change passwords"
  homepage "https://github.com/brycx/checkpwn"
  url "https://static.crates.io/crates/checkpwn/checkpwn-0.6.1.crate"
  sha256 "96b9c24f535d00f32031fe3b2d4bab9e6276ad5ad565b141ebf4f9d1bd197fa7"
  license "MIT"
  head "https://github.com/brycx/checkpwn.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "07ad1656c3a86038d73a815531416e7015998213e70e264cfcd9acb8a63f503a"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    output = shell_output("#{bin}/checkpwn acc test@example.com 2>&1", 101)
    assert_match "Failed to read or parse the configuration file 'checkpwn.yml'", output
  end
end
