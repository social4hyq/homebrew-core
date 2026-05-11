class Mkcert < Formula
  desc "Simple tool to make locally trusted development certificates"
  homepage "https://github.com/FiloSottile/mkcert"
  url "https://github.com/FiloSottile/mkcert/archive/refs/tags/v1.4.4.tar.gz"
  sha256 "32bd5519581bf0b03f53e5b22721692b99f39ab5b161dc27532c51eafa512ca9"
  license "BSD-3-Clause"
  head "https://github.com/FiloSottile/mkcert.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9d8b7c165d89133dbe6c15035613b0cf5a9d8a82789f7c2cd3e0242994f59cfb"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=v#{version}")
  end

  test do
    ENV["CAROOT"] = testpath
    system bin/"mkcert", "brew.test"
    assert_path_exists testpath/"brew.test.pem"
    assert_path_exists testpath/"brew.test-key.pem"
    output = (testpath/"brew.test.pem").read
    assert_match "-----BEGIN CERTIFICATE-----", output
    output = (testpath/"brew.test-key.pem").read
    assert_match "-----BEGIN PRIVATE KEY-----", output
  end
end
