class Darkhttpd < Formula
  desc "Small static webserver without CGI"
  homepage "https://unix4lyfe.org/darkhttpd/"
  url "https://github.com/emikulic/darkhttpd/archive/refs/tags/v1.17.tar.gz"
  sha256 "4fee9927e2d8bb0a302f0dd62f9ff1e075748fa9f5162c9481a7a58b41462b56"
  license "ISC"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "360c7451f968ac3d352c1f4cdfb1f2a391aca136e2cfe8fba36bde2dacd4ddcf"
  end

  def install
    system "make"
    bin.install "darkhttpd"
  end

  test do
    system bin/"darkhttpd", "--help"
  end
end
