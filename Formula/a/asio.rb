class Asio < Formula
  desc "Cross-platform C++ Library for asynchronous programming"
  homepage "https://think-async.com/Asio/"
  url "https://downloads.sourceforge.net/project/asio/asio/1.38.2%20%28Stable%29/asio-1.38.2.tar.bz2"
  sha256 "c04e0e66ac29741faad763a56f3c50196421d4b968009fc237c53314769bf8ad"
  license "BSL-1.0"
  revision 1
  compatibility_version 1

  livecheck do
    url :stable
    regex(%r{url=.*?Stable.*?/asio[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "24f0375a0088112bc40bf09fe309bf7697b4bb63a6f7c09988706df74b21bd47"
  end

  head do
    url "https://github.com/chriskohlhoff/asio.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on "openssl@3"

  def install
    ENV.cxx11

    if build.head?
      cd "asio"
      system "./autogen.sh"
    end

    system "./configure", "--disable-silent-rules",
                          "--without-boost",
                          "--with-openssl=#{Formula["openssl@3"].opt_prefix}",
                          *std_configure_args
    system "make", "install"
    pkgshare.install "src/examples"
  end

  test do
    found = Dir[pkgshare/"examples/cpp{11,03}/http/server/http_server"]
    raise "no http_server example file found" if found.empty?

    port = free_port
    pid = spawn found.first, "127.0.0.1", port.to_s, "."
    begin
      sleep 5
      assert_match "404 Not Found", shell_output("curl http://127.0.0.1:#{port}")
    ensure
      Process.kill 9, pid
    end
  end
end
