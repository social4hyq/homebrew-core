class Elio < Formula
  desc "Batteries-included terminal file manager with rich previews"
  homepage "https://github.com/elio-fm/elio"
  url "https://github.com/elio-fm/elio/archive/refs/tags/v1.9.0.tar.gz"
  sha256 "c8a43ff0fd8ffcbbf48296b6d26ad02a123e882cbfb832a0a9c2e3c00576109b"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9b5375c72ef1ad01a7fa6e7395c1a87fd0032ef6399f173046200378e7a4912d"
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
