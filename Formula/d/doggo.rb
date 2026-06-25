class Doggo < Formula
  desc "Command-line DNS Client for Humans"
  homepage "https://doggo.mrkaran.dev/"
  url "https://github.com/mr-karan/doggo/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "ddea7da5f8e6263626ffbff57e3df5e84df4343a740b2f7a8dae2505aae645d9"
  license "GPL-3.0-or-later"
  head "https://github.com/mr-karan/doggo.git", branch: "main"

  bottle do
    root_url "http://192.168.0.27:20080/bottles"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d18e40628351e6b323ad59d506a204d9351bc400e50e2d00874c7e3061866597"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.buildVersion=#{version} -X main.buildDate=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/doggo"

    generate_completions_from_executable(bin/"doggo", "completions")
  end

  test do
    answer = shell_output("#{bin}/doggo --short example.com NS @1.1.1.1")
    assert_equal "hera.ns.cloudflare.com.\nelliott.ns.cloudflare.com.\n", answer

    assert_match version.to_s, shell_output("#{bin}/doggo --version")
  end
end
