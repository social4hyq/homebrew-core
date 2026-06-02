class Fnm < Formula
  desc "Fast and simple Node.js version manager"
  homepage "https://github.com/Schniz/fnm"
  url "https://github.com/Schniz/fnm/archive/refs/tags/v1.39.0.tar.gz"
  sha256 "224081a677a02acd9f972885e824a98fa3843f5b778b28400ad5af97752f6127"
  license "GPL-3.0-only"
  head "https://github.com/Schniz/fnm.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "70766b23db17d169684ff0d05a2e4fe5c7c2cc42be5a3063d6aea84549bfb6a4"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"fnm", "completions", "--shell")
  end

  test do
    system bin/"fnm", "--version"
  end
end
