class Csprecon < Formula
  desc "Discover new target domains using Content Security Policy"
  homepage "https://github.com/edoardottt/csprecon"
  url "https://github.com/edoardottt/csprecon/archive/refs/tags/v0.4.6.tar.gz"
  sha256 "99deab536e5dc436d43f1971222b196e82fdaa1ba9b43684239ef8b723b01f6d"
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
