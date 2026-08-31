class Godap < Formula
  desc "Complete TUI (terminal user interface) for LDAP"
  homepage "https://github.com/Macmod/godap"
  url "https://github.com/Macmod/godap/archive/refs/tags/v2.12.2.tar.gz"
  sha256 "4e1d6e34c50fdeeb98e7d49d2e7164348c9395f5327920468ede0c32eb12adff"
  license "MIT"
  head "https://github.com/Macmod/godap.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e3dc4375e33c4e245fb6fea6df7ec1cd511a50212e2335896b1e4d84dc0ddb70"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-X main.Version=#{version}")
    generate_completions_from_executable(bin/"godap", shell_parameter_format: :cobra)
  end

  test do
    output = shell_output("#{bin}/godap -T 1 203.0.113.1 2>&1", 1)
    assert_match "determine target hostname for TLS verification: reverse lookup 203.0.113.1", output

    assert_match version.to_s, shell_output("#{bin}/godap version")
  end
end
