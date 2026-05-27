class Selecta < Formula
  desc "Fuzzy text selector for files and anything else you need to select"
  homepage "https://github.com/garybernhardt/selecta"
  url "https://github.com/garybernhardt/selecta/archive/refs/tags/v0.0.8.tar.gz"
  sha256 "737aae1677fdec1781408252acbb87eb615ad3de6ad623d76c5853e54df65347"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dc21d42d9db1bef3bd62e5ad9d788781eab097a2256298bd7235e12585cbb70d"
  end

  uses_from_macos "ruby"

  def install
    bin.install "selecta"
  end

  test do
    system bin/"selecta", "--version"
  end
end
