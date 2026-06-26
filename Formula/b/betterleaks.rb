class Betterleaks < Formula
  desc "Secrets scanner built for configurability and speed"
  homepage "https://github.com/betterleaks/betterleaks"
  url "https://github.com/betterleaks/betterleaks/archive/refs/tags/v1.6.0.tar.gz"
  sha256 "37d077a82e71add680f659b24f67dbd304b87254fe144080457208cd65b4b970"
  license "MIT"
  head "https://github.com/betterleaks/betterleaks.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3b5f7966d518bcd13324b56724c387b5cdf6f5c801f63589024ccdf320d7e642"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X github.com/betterleaks/betterleaks/version.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"betterleaks", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/betterleaks --version")

    (testpath/"betterleaks.toml").write <<~TOML
      title = "test-config"

      [[rules]]
      id = "custom-secret"
      regex = '''SECRET_[A-Z0-9]{8}'''
    TOML

    (testpath/"secrets.txt").write "prefix SECRET_ABC12345 suffix"

    report = testpath/"report.json"
    output = shell_output(
      "#{bin}/betterleaks dir --no-banner --log-level error " \
      "--config #{testpath}/betterleaks.toml " \
      "--report-format json --report-path #{report} #{testpath}/secrets.txt 2>&1",
      1,
    )
    assert_empty output

    findings = JSON.parse(report.read)
    assert_equal 1, findings.length
    assert_equal "custom-secret", findings.first["RuleID"]
  end
end
