class Wayback < Formula
  desc "Archiving tool integrated with various archival services"
  homepage "https://docs.wabarc.eu.org"
  url "https://github.com/wabarc/wayback/archive/refs/tags/v0.21.1.tar.gz"
  sha256 "b52cf015420852b99246cde0d0183ec746a1c851ff2e9ebbed80e05be7eccfa7"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "38d65d8c0489adc7a9470507cb7fe58c84748d100ee8642d484c87b6f926d4cd"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/wabarc/wayback/version.Version=#{version}
      -X github.com/wabarc/wayback/version.Commit=#{tap.user}
      -X github.com/wabarc/wayback/version.BuildDate=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/wayback"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wayback --version")

    output = shell_output("#{bin}/wayback --ia https://brew.sh 2>&1")
    assert_match(%r{https://web\.archive\.org/web/\d{14}/https://brew\.sh/}, output)
  end
end
