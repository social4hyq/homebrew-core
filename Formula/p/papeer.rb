class Papeer < Formula
  desc "Convert websites into eBooks and Markdown"
  homepage "https://papeer.tech"
  url "https://github.com/lapwat/papeer/archive/refs/tags/v0.9.1.tar.gz"
  sha256 "102c77d982228794028d83b637a2491de10fb34314a2a9f07a363a45fd73eaea"
  license "GPL-3.0-only"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9f6714ccff1ab97307f7c2602102b2361bee243894557eceac163d3f383c718f"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"papeer", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/papeer version")

    output = shell_output("#{bin}/papeer list https://12factor.net/ --selector='section.concrete>article>h2>a'")
    assert_match "8  VIII. Concurrency", output
  end
end
