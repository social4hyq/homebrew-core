class Csprecon < Formula
  desc "Discover new target domains using Content Security Policy"
  homepage "https://github.com/edoardottt/csprecon"
  url "https://github.com/edoardottt/csprecon/archive/refs/tags/v0.4.7.tar.gz"
  sha256 "93f448d1c8b9f4b45e066fb84665410f554fc815cad75c9cb8aa1b0df2cceab5"
  license "MIT"
  head "https://github.com/edoardottt/csprecon.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f58702f53bb761ba80551469425385f6eb77eb416098120155242cda35c95807"
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
