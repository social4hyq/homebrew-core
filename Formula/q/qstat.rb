class Qstat < Formula
  desc "Query Quake servers from the command-line"
  homepage "https://github.com/Unity-Technologies/qstat"
  url "https://github.com/Unity-Technologies/qstat/archive/refs/tags/v2.18.tar.gz"
  sha256 "a74564bd9c31db3dc1fcc0a68ffaf694630b9e67f0d31ff76b2a3c3196ee4f1f"
  license "Artistic-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e0213b024a8a9e524aeaa1e031563c0d130e7dd6b2a85668611a65ab02b5ee73"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  def install
    system "autoupdate" unless OS.mac?
    system "./autogen.sh"
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"qstat", "--help"
  end
end
