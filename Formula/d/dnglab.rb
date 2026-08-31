class Dnglab < Formula
  desc "Camera RAW to DNG file format converter"
  homepage "https://github.com/dnglab/dnglab"
  url "https://github.com/dnglab/dnglab/archive/refs/tags/v0.8.0.tar.gz"
  sha256 "432b8ac8f553289e06c0d78b37ae6f9546e80b736ef879f2ee66b66345590c4d"
  license "LGPL-2.1-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "caba6fdf34d647abb17116d60180e1602e7d779e7bd141559d3a6374c11129b5"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "bin/dnglab")

    bash_completion.install "bin/dnglab/completions/dnglab.bash"
    fish_completion.install "bin/dnglab/completions/dnglab.fish"
    zsh_completion.install "bin/dnglab/completions/_dnglab"

    man1.install Dir["bin/dnglab/manpages/*.1"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dnglab --version")

    touch testpath/"not_a_dng.dng"
    output = shell_output("#{bin}/dnglab analyze --raw-checksum not_a_dng.dng 2>&1", 7)
    assert_match "Error: No decoder found, model '', make: '', mode: ''", output
  end
end
