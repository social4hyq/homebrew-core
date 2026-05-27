class Lemmeknow < Formula
  desc "Fastest way to identify anything!"
  homepage "https://github.com/swanandx/lemmeknow"
  url "https://github.com/swanandx/lemmeknow/archive/refs/tags/v0.8.0.tar.gz"
  sha256 "46f42e80cf2c142641fc52826bcf73e00e26dbb93f20397a282e04b786a7cfe8"
  license "MIT"
  head "https://github.com/swanandx/lemmeknow.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f820d7c0f63d245fce10456833f53eb23d25ad72b64b017caa4cbfdce974f34e"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "Internet Protocol (IP)", shell_output("#{bin}/lemmeknow 127.0.0.1").strip
  end
end
