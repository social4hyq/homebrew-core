class Dnsmap < Formula
  desc "Passive DNS network mapper (a.k.a. subdomains bruteforcer)"
  homepage "https://github.com/resurrecting-open-source-projects/dnsmap"
  url "https://github.com/resurrecting-open-source-projects/dnsmap/archive/refs/tags/0.36.tar.gz"
  sha256 "f52d6d49cbf9a60f601c919f99457f108d51ecd011c63e669d58f38d50ad853c"
  # Code is all GPL-2.0-or-later but license file was changed to GPL-3.0 in following commit
  # Ref: https://github.com/resurrecting-open-source-projects/dnsmap/commit/408ecfd62a0b2c089dda6f3be5d396ed2662797e
  license all_of: ["GPL-2.0-or-later", "GPL-3.0-or-later"]
  head "https://github.com/resurrecting-open-source-projects/dnsmap.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "739819a50539140079ca2def0a4653aac45c9f735af0b0a57f2118c969e124e4"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  def install
    system "./autogen.sh"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output(bin/"dnsmap", 1)
  end
end
