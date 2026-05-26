class TrzszSsh < Formula
  desc "Highly OpenSSH-compatible client with extended features"
  homepage "https://trzsz.github.io/tssh"
  url "https://github.com/trzsz/trzsz-ssh/archive/refs/tags/v0.1.25.tar.gz"
  sha256 "9a692854733333643b6108f68bed0239b266c461e15125781503d957c9b47842"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7613bc8b5d38c52f56860f89d23cb76deea870c7a7c29263c5458a4782f08048"
  end

  depends_on "go" => :build

  conflicts_with "tssh", because: "both install `tssh` binaries"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/"tssh"), "./cmd/tssh"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/tssh -v")

    assert_match "invalid option", shell_output("#{bin}/tssh -o abc 2>&1", 11)
    assert_match "invalid bind specification", shell_output("#{bin}/tssh -D xyz 2>&1", 11)
    assert_match "invalid forwarding specification", shell_output("#{bin}/tssh -L 123 2>&1", 11)
  end
end
