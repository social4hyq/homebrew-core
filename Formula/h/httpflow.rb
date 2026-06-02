class Httpflow < Formula
  desc "Packet capture and analysis utility similar to tcpdump for HTTP"
  homepage "https://github.com/six-ddc/httpflow"
  url "https://github.com/six-ddc/httpflow/archive/refs/tags/0.0.9.tar.gz"
  sha256 "2347bd416641e165669bf1362107499d0bc4524ed9bfbb273ccd3b3dd411e89c"
  license "MIT"
  head "https://github.com/six-ddc/httpflow.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a533963270a4ddceb432f416bb64659c2c03ed1ea9f07ec4e285bcd58ba410e2"
  end

  # Last release on 2020-05-07 and needs EOL `pcre` (https://github.com/six-ddc/httpflow/issues/12)
  deprecate! date: "2026-01-10", because: :unmaintained
  disable! date: "2027-01-10", because: :unmaintained

  depends_on "pcre"

  uses_from_macos "libpcap"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "make"
    system "make", "install", "PREFIX=#{prefix}", "CXX=#{ENV.cxx}"
  end

  test do
    system bin/"httpflow", "-h"
  end
end
