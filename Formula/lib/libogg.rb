class Libogg < Formula
  desc "Ogg Bitstream Library"
  homepage "https://www.xiph.org/ogg/"
  url "https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.6.tar.gz"
  mirror "https://github.com/xiph/ogg/releases/download/v1.3.6/libogg-1.3.6.tar.gz"
  sha256 "83e6704730683d004d20e21b8f7f55dcb3383cdf84c0daedf30bde175f774638"
  license "BSD-3-Clause"
  revision 1
  compatibility_version 1
  head "https://gitlab.xiph.org/xiph/ogg.git", branch: "main"

  livecheck do
    url "https://ftp.osuosl.org/pub/xiph/releases/ogg/?C=M&O=D"
    regex(%r{href=(?:["']?|.*?/)libogg[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "75f8144e3adc49d400d52622b8bd83292c0682010b7bae8c79bf02e5ca740ccb"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DBUILD_SHARED_LIBS=TRUE", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    system "cmake", "-S", ".", "-B", "build-static", "-DBUILD_SHARED_LIBS=FALSE", *std_cmake_args
    system "cmake", "--build", "build-static"
    lib.install "build-static/libogg.a"
  end

  test do
    resource "oggfile" do
      url "https://upload.wikimedia.org/wikipedia/commons/c/c8/Example.ogg"
      sha256 "f57b56d8aae4c847cf01224fb45293610d801cfdac43d932b5eeab1cd318182a"
    end

    (testpath/"test.c").write <<~C
      #include <ogg/ogg.h>
      #include <stdio.h>

      int main (void) {
        ogg_sync_state oy;
        ogg_stream_state os;
        ogg_page og;
        ogg_packet op;
        char *buffer;
        int bytes;

        ogg_sync_init (&oy);

        // Read all available input to avoid broken pipe
        do {
          buffer = ogg_sync_buffer (&oy, 4096);
          bytes = fread(buffer, 1, 4096, stdin);
          ogg_sync_wrote (&oy, bytes);
        } while (bytes == 4096);

        if (ogg_sync_pageout (&oy, &og) != 1)
          return 1;
        ogg_stream_init (&os, ogg_page_serialno (&og));
        if (ogg_stream_pagein (&os, &og) < 0)
          return 1;
        if (ogg_stream_packetout (&os, &op) != 1)
         return 1;

        return 0;
      }
    C
    testpath.install resource("oggfile")
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-logg",
                   "-o", "test"

    # Should work on an OGG file
    pipe_output("./test", (testpath/"Example.ogg").read, 0)

    # Expected to fail on a non-OGG file
    pipe_output("./test", test_fixtures("test.wav").read, 1)
  end
end
