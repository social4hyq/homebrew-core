class Mongoose < Formula
  desc "Web server build on top of Libmongoose embedded library"
  homepage "https://mongoose.ws/"
  url "https://github.com/cesanta/mongoose/archive/refs/tags/7.22.tar.gz"
  sha256 "87727cd2c240ff559b16e9710d44b61ba3513dbee50428bd8ee1596d7c58460a"
  license "GPL-2.0-only"

  bottle do
    root_url "http://192.168.0.27:20080/bottles"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ff1f4286459fc546c4b7e489d0e4ea65ded48f6f7031d40899a1ea059189b5a6"
  end

  def install
    # No Makefile but is an expectation upstream of binary creation
    # https://github.com/cesanta/mongoose/issues/326
    system "make", "-C", "tutorials/http/http-server", "example"
    bin.install "tutorials/http/http-server/example" => "mongoose"

    system ENV.cc, "-dynamiclib", "mongoose.c", "-o", "libmongoose.dylib" if OS.mac?
    if OS.linux?
      system ENV.cc, "-fPIC", "-c", "mongoose.c"
      system ENV.cc, "-shared", "-Wl,-soname,libmongoose.so", "-o", "libmongoose.so", "mongoose.o", "-lc", "-lpthread"
    end
    lib.install shared_library("libmongoose")
    include.install "mongoose.h"
    pkgshare.install "tutorials"
    doc.install Dir["docs/*"]
  end

  test do
    (testpath/"hello.html").write <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <title>Homebrew</title>
        </head>
        <body>
          <p>Hi!</p>
        </body>
      </html>
    HTML

    begin
      pid = fork { exec bin/"mongoose" }
      sleep 2
      assert_match "Hi!", shell_output("curl http://localhost:8000/hello.html")
    ensure
      Process.kill("SIGINT", pid)
      Process.wait(pid)
    end
  end
end
