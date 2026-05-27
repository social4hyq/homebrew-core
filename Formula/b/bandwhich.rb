class Bandwhich < Formula
  desc "Terminal bandwidth utilization tool"
  homepage "https://github.com/imsnif/bandwhich"
  url "https://github.com/imsnif/bandwhich/archive/refs/tags/v0.23.1.tar.gz"
  sha256 "aafb96d059cf9734da915dca4f5940c319d2e6b54e2ffb884332e9f5e820e6d7"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f3df7b433c4e43d3042183b490479e4d66cad084c946a6ddec986f26904239cb"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    out_dir = Dir["target/release/build/bandwhich-*/out"].first
    bash_completion.install "#{out_dir}/bandwhich.bash" => "bandwhich"
    fish_completion.install "#{out_dir}/bandwhich.fish"
    zsh_completion.install "#{out_dir}/_bandwhich"
    pwsh_completion.install "#{out_dir}/_bandwhich.ps1"

    man1.install "#{out_dir}/bandwhich.1"
  end

  test do
    output = shell_output "#{bin}/bandwhich --interface bandwhich", 1
    assert_match output, "Error: Cannot find interface bandwhich"
  end
end
