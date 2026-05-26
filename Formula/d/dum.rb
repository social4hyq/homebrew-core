class Dum < Formula
  desc "Npm scripts runner written in Rust"
  homepage "https://github.com/egoist/dum"
  url "https://github.com/egoist/dum/archive/refs/tags/v0.1.20.tar.gz"
  sha256 "a1f4890f7edec4b5a376d3d6a30986b13ef8818593732f4a577a35c3c7145503"
  license "MIT"
  head "https://github.com/egoist/dum.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "46e493ed2ba6b263dcab97d4b260aab6d4a0d7768ab296294ee50a6ba23d04fe"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"package.json").write <<~JSON
      {
        "scripts": {
          "hello": "echo 'Hello, dum!'"
        }
      }
    JSON

    output = shell_output("#{bin}/dum run hello")
    assert_match "Hello, dum!", output

    assert_match version.to_s, shell_output("#{bin}/dum --version")
  end
end
