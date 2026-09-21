class Ghr < Formula
  desc "Upload multiple artifacts to GitHub Release in parallel"
  # homepage bug report, https://github.com/tcnksm/ghr/issues/168
  homepage "https://github.com/tcnksm/ghr"
  url "https://github.com/tcnksm/ghr/archive/refs/tags/v0.18.4.tar.gz"
  sha256 "d95ef0cb78ec9f137c40cadaf2e8ba8858fb495399122abd44ff0b9a82ffd48f"
  license "MIT"
  head "https://github.com/tcnksm/ghr.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9e9c78f9bc1be0293b206bb6673aab73c2bac0144e4bfc35cf1e6848cfe31319"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    ENV["GITHUB_TOKEN"] = nil
    args = "-username testbot -repository #{testpath} v#{version} #{Dir.pwd}"
    assert_includes "token not found", shell_output("#{bin}/ghr #{args}", 15)
  end
end
