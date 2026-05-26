class Shuffledns < Formula
  desc "Enumerate subdomains using active bruteforce & resolve subdomains with wildcards"
  homepage "https://github.com/projectdiscovery/shuffledns"
  url "https://github.com/projectdiscovery/shuffledns/archive/refs/tags/v1.2.1.tar.gz"
  sha256 "f1a067b81980c57c9c024aab5988c78cb93159312d6fcf5c2ba0fd6b46d6f4e0"
  license "GPL-3.0-or-later"
  head "https://github.com/projectdiscovery/shuffledns.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "24fe09565eae1ec320851cd3471d9aea277606dac1ef2214afb1f35c0f84012e"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/shuffledns"
  end

  test do
    assert_match "resolver file doesn't exists", shell_output("#{bin}/shuffledns 2>&1", 1)
    assert_match version.to_s, shell_output("#{bin}/shuffledns -version 2>&1")
  end
end
