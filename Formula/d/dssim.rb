class Dssim < Formula
  desc "RGBA Structural Similarity Rust implementation"
  homepage "https://github.com/kornelski/dssim"
  url "https://github.com/kornelski/dssim/archive/refs/tags/3.4.0.tar.gz"
  sha256 "5267e79f4604558d9f24ce02aa20597396a9b052d0ad1b2f8000d4d6bd162126"
  license "AGPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "22c57c70b5102976aa466ac5b8be8ad437cd230dae436c17c23babc6dc4d89e7"
  end

  depends_on "rust" => :build

  on_intel do
    depends_on "nasm" => :build
  end

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    system bin/"dssim", test_fixtures("test.png"), test_fixtures("test.png")
  end
end
