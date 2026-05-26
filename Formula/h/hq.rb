class Hq < Formula
  desc "Jq, but for HTML"
  homepage "https://github.com/orf/html-query"
  url "https://github.com/orf/html-query/archive/refs/tags/html-query-v1.2.2.tar.gz"
  sha256 "0fdc12100c178cd2e5ae61c54e640ecb68533017fcee4845ceb4050d1e4fff60"
  license "MIT"

  livecheck do
    url :stable
    regex(/^html-query[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0bc7886cb0d5f3b2dd39bd66188c1b955e822c7194b2ed877a6e9ef7bb48c7aa"
  end

  depends_on "rust" => :build

  conflicts_with "proxygen", because: "both install `hq` binaries"

  def install
    system "cargo", "install", *std_cargo_args(path: "html-query")
  end

  test do
    html = testpath/"test.html"
    html.write <<~EOS
      <p class="foo">Test</p>
    EOS
    output = shell_output("#{bin}/hq '{foo: .foo}' test.html")
    assert_match '{"foo":"Test"}', output
  end
end
