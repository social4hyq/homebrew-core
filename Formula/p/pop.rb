class Pop < Formula
  desc "Send emails from your terminal"
  homepage "https://github.com/charmbracelet/pop"
  url "https://github.com/charmbracelet/pop/archive/refs/tags/v0.2.1.tar.gz"
  sha256 "365b989dcd0c45256e304ddd8e7a4be8ac146ed24a5751930259c56c23a16dec"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "375844768881e9ef16d9dc35d72a27d38d81ad87bccca3adadb390dc05cabc2a"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"pop", shell_parameter_format: :cobra)
    (man1/"pop.1").write Utils.safe_popen_read(bin/"pop", "man")
  end

  test do
    assert_match "environment variable is required",
      shell_output("#{bin}/pop --body 'hi' --subject 'Hello'", 1).chomp

    assert_match version.to_s, shell_output("#{bin}/pop --version")
  end
end
