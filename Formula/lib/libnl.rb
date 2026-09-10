class Libnl < Formula
  desc "Netlink Library Suite"
  homepage "https://github.com/thom311/libnl"
  url "https://github.com/thom311/libnl/releases/download/libnl3_12_0/libnl-3.12.0.tar.gz"
  sha256 "fc51ca7196f1a3f5fdf6ffd3864b50f4f9c02333be28be4eeca057e103c0dd18"
  license "LGPL-2.1-or-later"
  revision 1

  livecheck do
    url :stable
    regex(/^libnl(\d+(?:[._]\d+)+)$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d70c519fc9bc291df558f39d21eaf0a9c3aded57b1b0d4f2ca06a992ca0a1a3e"
  end

  depends_on "bison" => :build
  depends_on "flex" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on :linux # Netlink sockets are only available in Linux.

  def install
    # Harmonybrew injects -D__MUSL__, which causes OHOS SDK's sys/socket.h to skip
    # the sockaddr_storage definition, but netinet/in.h and netinet/tcp.h need it.
    # Use absolute path to bypass libnl's private linux/socket.h shadow.
    ENV.append_to_cflags "-include /opt/ohos-sdk/ohos/native/sysroot/usr/include/linux/socket.h"
    system "./configure", "--disable-silent-rules", "--sysconfdir=#{etc}", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <netlink/netlink.h>
      #include <netlink/route/link.h>

      #include <linux/netlink.h>

      int main(int argc, char *argv[])
      {
        struct rtnl_link *link;
        struct nl_sock *sk;
        int err;

        sk = nl_socket_alloc();
        if ((err = nl_connect(sk, NETLINK_ROUTE)) < 0) {
          nl_perror(err, "Unable to connect socket");
          return err;
        }

        link = rtnl_link_alloc();
        rtnl_link_set_name(link, "my_bond");

        if ((err = rtnl_link_delete(sk, link)) < 0) {
          nl_perror(err, "Unable to delete link");
          return err;
        }

        rtnl_link_put(link);
        nl_close(sk);

        return 0;
      }
    C

    flags = shell_output("pkgconf --cflags --libs libnl-3.0 libnl-route-3.0").chomp.split
    # -D__MUSL__ prevents sys/socket.h from defining sockaddr_storage,
    # avoiding redefinition conflict with linux/socket.h.
    system ENV.cc, "-D__MUSL__", "test.c", "-o", "test", *flags
    assert_match "Unable to delete link: Operation not permitted", shell_output("./test 2>&1", 228)

    assert_match "inet 127.0.0.1", shell_output("#{bin}/nl-route-list")
  end
end
