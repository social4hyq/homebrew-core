class Lexido < Formula
  desc "Innovative assistant for the command-line"
  homepage "https://github.com/micr0-dev/lexido"
  url "https://github.com/micr0-dev/lexido/archive/refs/tags/v1.4.3.tar.gz"
  sha256 "c39cf8f93cce2480773c9099ece1d8a90c1e350cf48cad56eebea96fbc04981f"
  license "AGPL-3.0-or-later"
  head "https://github.com/micr0-dev/lexido.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dd52015d1dcf4cebdfee1555dd9c2acbca070e8201882b8df92a3a61870b798f"
  end

  deprecate! date: "2025-12-21", because: :repo_archived
  disable! date: "2026-12-21", because: :repo_archived

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    # Run the `lexido` command and ensure it outputs the expected error message
    output = shell_output("#{bin}/lexido -l 2>&1", 1)
    assert_match "Error initializing ollama: ollama not installed on system,", output
    assert_match "please install it first using the guide on", output
    assert_match "https://github.com/micr0-dev/lexido?tab=readme-ov-file#running-locally", output
  end
end
