class Redu < Formula
  desc "Ncdu for your restic repository"
  homepage "https://github.com/drdo/redu"
  url "https://github.com/drdo/redu/archive/refs/tags/v0.2.15.tar.gz"
  sha256 "09fda46231cf49663486a0f4a3ab0f217f39dc1f0ba1bcd05917e77e6f7447a2"
  license "MIT"
  head "https://github.com/drdo/redu.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "97bae7fdba070a14db7a8482ff0ce38ad6309d4fd041b3a4c11540f878472740"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/redu --version")
    assert_match "Error: restic error", shell_output("#{bin}/redu --repo mock_repo mock_pw 2>&1", 1)
  end
end
