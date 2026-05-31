class Libhubbub < Formula
  desc "HTML parser library"
  homepage "https://www.netsurf-browser.org/projects/hubbub/"
  url "https://download.netsurf-browser.org/libs/releases/libhubbub-0.3.8-src.tar.gz"
  sha256 "8ac1e6f5f3d48c05141d59391719534290c59cd029efc249eb4fdbac102cd5a5"
  license "MIT"
  head "git://git.netsurf-browser.org/libhubbub.git", branch: "master"

  livecheck do
    url :homepage
    regex(/href=.*?libhubbub[._-]v?(\d+(?:\.\d+)+)[._-]src\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "166251f99ee9d0392a3fd1f4de737f37a6bf22c2c3eb674f661709ac2fbfc116"
  end

  depends_on "netsurf-buildsystem" => :build
  depends_on "pkgconf" => :build
  depends_on "libparserutils"

  uses_from_macos "gperf" => :build

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
      #include <hubbub/parser.h>

      int main() {
          hubbub_parser *parser;
          hubbub_error error;

          error = hubbub_parser_create("UTF-8", false, &parser);
          if (error != HUBBUB_OK) {
              return 1;
          }

          hubbub_parser_destroy(parser);
          return 0;
      }
    C

    system ENV.cc, "test.c", "-o", "test", "-L#{lib}", "-lhubbub"
    system "./test"
  end
end
