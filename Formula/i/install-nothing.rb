class InstallNothing < Formula
  desc "Simulates installing things but doesn't actually install anything"
  homepage "https://github.com/buyukakyuz/install-nothing"
  url "https://github.com/buyukakyuz/install-nothing/archive/refs/tags/v0.5.0.tar.gz"
  sha256 "de1afd428496e8d7228e2023104613098808994b0c3859565fd02d41e86928f9"
  license "MIT"
  head "https://github.com/buyukakyuz/install-nothing.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "25347f49ec48ca780b7049c21e17f1e03976d3954f5b5890ae58c15d0e036e9f"
  end

  depends_on "rust" => :build

  # version patch, upstream pr ref, ps://github.com/buyukakyuz/install-nothing/pull/14
  patch do
    url "https://github.com/buyukakyuz/install-nothing/commit/1933dfd5ac5f8e6572b6cb0d8fde8b152fb51540.patch?full_index=1"
    sha256 "11ffb9c283c1d38933de854468b2f6c6001aa5d4886961a7372dde3ea602d44d"
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    # install-nothing is a TUI application
    assert_match version.to_s, shell_output("#{bin}/install-nothing --version")
  end
end
