class Oak < Formula
  desc "Expressive, simple, dynamic programming language"
  homepage "https://oaklang.org/"
  url "https://github.com/thesephist/oak/archive/refs/tags/v0.3.tar.gz"
  sha256 "05bc1c09da8f8d199d169e5a5c5ab2f2923bad6fac624f497f5ea365f378e38a"
  license "MIT"
  head "https://github.com/thesephist/oak.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8afacdb460552ab1a009b0bd223b1014d317c9aea4ed05016a8e76caf92dd267"
  end

  depends_on "go" => :build

  conflicts_with "oakc", because: "both install `oak` binaries"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    assert_equal "Hello, World!\n14\n", shell_output("#{bin}/oak eval \"std.println('Hello, World!')\"")
  end
end
