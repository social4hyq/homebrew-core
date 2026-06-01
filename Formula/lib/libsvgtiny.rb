class Libsvgtiny < Formula
  desc "Implementation of SVG Tiny"
  homepage "https://www.netsurf-browser.org/projects/libsvgtiny/"
  url "https://download.netsurf-browser.org/libs/releases/libsvgtiny-0.1.8-src.tar.gz"
  sha256 "c357227f02e83fb2a76b12b901191a082229db1f007362e8f31c754510c2a01c"
  license "MIT"

  livecheck do
    url "https://download.netsurf-browser.org/libs/releases/"
    regex(/href=.*?libsvgtiny[._-]v?(\d+(?:\.\d+)+)[._-]src\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c2ef0707da02d5213c593aff7a555fe1d870da61c9ae6b984f1b62a2a148672e"
  end

  depends_on "netsurf-buildsystem" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "libdom"
  depends_on "libhubbub"
  depends_on "libparserutils"
  depends_on "libwapcaplet"

  uses_from_macos "gperf" => :build
  uses_from_macos "expat"

  def install
    args = %W[
      NSSHARED=#{Formula["netsurf-buildsystem"].opt_pkgshare}
      PREFIX=#{prefix}
    ]

    system "make", "install", "COMPONENT_TYPE=lib-shared", *args
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <sys/types.h>
      #include <sys/stat.h>
      #include <unistd.h>
      #include <stdlib.h>
      #include <svgtiny.h>

      int main(int argc, char *argv[]) {
        FILE *fd;
        struct stat sb;
        char *buffer;
        size_t size, n;
        struct svgtiny_diagram *diagram;
        svgtiny_code code;

        if (argc != 2) {
          printf("Usage: %s FILE\\n", argv[0]);
          return 1;
        }

        fd = fopen(argv[1], "rb");
        if (!fd) {
          perror(argv[1]);
          return 1;
        }

        if (stat(argv[1], &sb)) {
          perror(argv[1]);
          return 1;
        }
        size = sb.st_size;

        buffer = malloc(size);
        if (!buffer) {
          printf("Unable to allocate %lld bytes\\n",
                          (long long) size);
          return 1;
        }

        n = fread(buffer, 1, size, fd);
        if (n != size) {
          perror(argv[1]);
          return 1;
        }

        fclose(fd);

        diagram = svgtiny_create();
        if (!diagram) {
          printf("svgtiny_create failed\\n");
          return 1;
        }

        code = svgtiny_parse(diagram, buffer, size, argv[1], 1000, 1000);
        switch (code) {
        case svgtiny_OK:
          printf("svgtiny_OK");
          break;
        case svgtiny_OUT_OF_MEMORY:
          printf("svgtiny_OUT_OF_MEMORY");
          break;
        case svgtiny_LIBDOM_ERROR:
          printf("svgtiny_LIBDOM_ERROR");
          break;
        case svgtiny_NOT_SVG:
          printf("svgtiny_NOT_SVG");
          break;
        case svgtiny_SVG_ERROR:
          printf("svgtiny_SVG_ERROR: line %i: %s",
                          diagram->error_line,
                          diagram->error_message);
          break;
        default:
          printf("unknown svgtiny_code %i", code);
          break;
        }
        printf("\\n");

        free(buffer);
        svgtiny_free(diagram);

        return code;
      }
    C

    flags = shell_output("pkgconf --cflags --libs libsvgtiny").chomp.split
    system ENV.cc, testpath/"test.c", "-o", "test", *flags
    assert_equal "svgtiny_OK", shell_output("./test #{test_fixtures("test.svg")}").chomp
  end
end
