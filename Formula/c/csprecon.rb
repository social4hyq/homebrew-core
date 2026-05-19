class Csprecon < Formula
  desc "Discover new target domains using Content Security Policy"
  homepage "https://github.com/edoardottt/csprecon"
  url "https://github.com/edoardottt/csprecon/archive/refs/tags/v0.4.5.tar.gz"
  sha256 "9e68dc2c52d5190c6c70e84c7b9b0123d9eca60f8cda2587be614b31d6e3bff5"
  license "MIT"
  head "https://github.com/edoardottt/csprecon.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a6c49fb0f9773bb40ce14ce8936866097ffe769cccad706655158e58507891ec"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/csprecon"
  end

  test do
    output = shell_output("#{bin}/csprecon -u https://brew.sh")
    assert_match "avatars.githubusercontent.com", output
  end
end
