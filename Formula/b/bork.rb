class Bork < Formula
  desc "Bash-Operated Reconciling Kludge"
  homepage "https://bork.sh/"
  url "https://github.com/borksh/bork/archive/refs/tags/v0.14.0.tar.gz"
  sha256 "718331c54c94bf7eddeff089227c0f57093361f7e6e24066cb544cc9ebd2f6c5"
  license "Apache-2.0"
  head "https://github.com/borksh/bork.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "22cf6717f8f03c04918872f47b4d85c5be810ffc7b80c8d6c3e8b69f63b645d0"
  end

  def install
    man1.install "docs/bork.1"
    prefix.install %w[bin lib test types]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bork version")

    expected_output = "checking: directory #{testpath}/foo\r" \
                      "missing: directory #{testpath}/foo           \n" \
                      "verifying install: directory #{testpath}/foo\n" \
                      "* success\n"
    assert_match expected_output, shell_output("#{bin}/bork do ok directory #{testpath}/foo", 1)
  end
end
