class Drill < Formula
  desc "HTTP load testing application written in Rust"
  homepage "https://github.com/fcsonline/drill"
  url "https://github.com/fcsonline/drill/archive/refs/tags/0.9.0.tar.gz"
  sha256 "ac486698c33daecb2d099fbb890d0b37ffd9baf3655d620f57932e1d398b44fc"
  license "GPL-3.0-or-later"
  head "https://github.com/fcsonline/drill.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ab70cb65cce6fa9333edf12b4a60e9d7aef46d1180537988ea808b5881238dc1"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3" # Uses Secure Transport on macOS
  end

  conflicts_with "ldns", because: "both install a `drill` binary"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"benchmark.yml").write <<~YAML
      ---
      concurrency: 4
      base: 'https://dummyjson.com'
      iterations: 5
      rampup: 2

      plan:
        - name: Http status
          request:
            url: /http/200

        - name: Check products API
          request:
            url: /products/1
    YAML

    assert_match "Total requests            10",
      shell_output("#{bin}/drill --benchmark #{testpath}/benchmark.yml --stats")
  end
end
