class DerAscii < Formula
  desc "Reversible DER and BER pretty-printer"
  homepage "https://github.com/google/der-ascii"
  url "https://github.com/google/der-ascii/archive/refs/tags/v0.8.0.tar.gz"
  sha256 "1ab23597139a6e006efc38e1105b81bf8ca2486c3fab42be7a9ccabb8a1aef2a"
  license "Apache-2.0"
  head "https://github.com/google/der-ascii.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e027e6792bab63d759493210332d7d2986e680b58eb8beac35855a38ed412798"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(output: bin/"ascii2der", ldflags: "-s -w"), "./cmd/ascii2der"
    system "go", "build", *std_go_args(output: bin/"der2ascii", ldflags: "-s -w"), "./cmd/der2ascii"

    pkgshare.install "samples"
  end

  test do
    cp pkgshare/"samples/cert.txt", testpath
    system bin/"ascii2der", "-i", "cert.txt", "-o", "cert.der"
    output = shell_output("#{bin}/der2ascii -i cert.der")
    assert_match "Internet Widgits Pty Ltd", output
  end
end
