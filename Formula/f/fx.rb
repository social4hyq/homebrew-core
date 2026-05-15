class Fx < Formula
  desc "Terminal JSON viewer"
  homepage "https://fx.wtf"
  url "https://github.com/antonmedv/fx/archive/refs/tags/39.2.0.tar.gz"
  sha256 "cdb98177f956615c961bc615fab0b30e73167295152d4f2d4cb70b16cdf47d6e"
  license "MIT"
  head "https://github.com/antonmedv/fx.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7aede44d0111f939fa1de38506cf387bdf4040200d778198bab5b810a479e3d6"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
    generate_completions_from_executable(bin/"fx", "--comp")
  end

  test do
    assert_equal "42", pipe_output("#{bin}/fx .", "42").strip
  end
end
