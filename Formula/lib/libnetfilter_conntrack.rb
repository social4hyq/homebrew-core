class LibnetfilterConntrack < Formula
  desc "Library providing an API to the in-kernel connection tracking state table"
  homepage "https://www.netfilter.org/projects/libnetfilter_conntrack/"
  url "https://www.netfilter.org/pub/libnetfilter_conntrack/libnetfilter_conntrack-1.1.1.tar.xz"
  sha256 "769d3eaf57fa4fbdb05dd12873b6cb9a5be7844d8937e222b647381d44284820"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://www.netfilter.org/projects/libnetfilter_conntrack/downloads.html"
    regex(/href=.*?libnetfilter_conntrack[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7b8a9aadf10a1f3d449c2e7d44e9c9dbc488f7794ed018d5d3d0ad0522d821b1"
  end

  depends_on "pkgconf" => [:build, :test]
  depends_on "libmnl"
  depends_on "libnfnetlink"
  depends_on :linux

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
    pkgshare.install "examples"
  end

  test do
    flags = shell_output("pkgconf --cflags --libs libnetfilter_conntrack libmnl").chomp.split
    system ENV.cc, "-D__MUSL__", pkgshare/"examples/nfct-mnl-get.c", "-o", "nfct-mnl-get", *flags
    assert_match "mnl_socket_recvfrom: Operation not permitted", shell_output("./nfct-mnl-get inet 2>&1", 1)
  end
end
