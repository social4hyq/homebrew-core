class Corkscrew < Formula
  desc "Tunnel SSH through HTTP proxies"
  homepage "https://packages.debian.org/sid/corkscrew"
  url "https://deb.debian.org/debian/pool/main/c/corkscrew/corkscrew_2.0.orig.tar.gz"
  sha256 "0d0fcbb41cba4a81c4ab494459472086f377f9edb78a2e2238ed19b58956b0be"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://deb.debian.org/debian/pool/main/c/corkscrew/"
    regex(/href=.*?corkscrew[._-]v?(\d+(?:\.\d+)+)\.orig\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "908c77780dbc28f227d8e868a488e9127a963c412c92c2b9d2ddca45f6906038"
  end

  depends_on "libtool" => :build

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-implicit-int" if DevelopmentTools.clang_build_version >= 1403

    cp Dir["#{Formula["libtool"].opt_share}/libtool/*/config.{guess,sub}"], buildpath
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    port = free_port

    fork do
      server = TCPServer.new port
      socket = server.accept
      Open3.popen3("#{bin}/corkscrew 127.0.0.1 #{port} www.google.com 80") do |_, stdout, _|
        socket.write "GET /index.html HTTP/1.1\r\n\r\n"
        assert_match "HTTP/1.1", stdout.gets("\r\n\r\n")
      end
    end
  end
end
