class Betterleaks < Formula
  desc "Secrets scanner built for configurability and speed"
  homepage "https://github.com/betterleaks/betterleaks"
  url "https://github.com/betterleaks/betterleaks/archive/refs/tags/v1.3.1.tar.gz"
  sha256 "c2994ebc253010eae1b0131677a12759fdfb756873180be07bd81d0420f1430c"
  license "MIT"
  head "https://github.com/betterleaks/betterleaks.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "90a5b77c5377956359589d7ecf71c1a046054b5b43b215e2a5b124ea71290f62"
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
