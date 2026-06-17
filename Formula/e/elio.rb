class Elio < Formula
  desc "Batteries-included terminal file manager with rich previews"
  homepage "https://github.com/elio-fm/elio"
  url "https://github.com/elio-fm/elio/archive/refs/tags/v1.9.0.tar.gz"
  sha256 "c8a43ff0fd8ffcbbf48296b6d26ad02a123e882cbfb832a0a9c2e3c00576109b"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bc3ab7b15d0c3e660c75f75b8f5dacfbaaeb13cc61f72b86db54ba36d0b0e3fb"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    missing = testpath/"missing-directory"
    output = shell_output("#{bin}/elio #{missing} 2>&1", 1)
    assert_match "no such file or directory", output
  end
end
