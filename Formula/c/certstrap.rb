class Certstrap < Formula
  desc "Tools to bootstrap CAs, certificate requests, and signed certificates"
  homepage "https://github.com/square/certstrap"
  url "https://github.com/square/certstrap/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "4b32289c20dfad7bf8ab653c200954b3b9981fcbf101b699ceb575c6e7661a90"
  license "Apache-2.0"
  head "https://github.com/square/certstrap.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d16fd9e79d10555dda82ee62362457354525eaa734f6cc5fd6ff199b5b67bd8b"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    system bin/"certstrap", "init", "--common-name", "Homebrew Test CA", "--passphrase", "beerformyhorses"
  end
end
