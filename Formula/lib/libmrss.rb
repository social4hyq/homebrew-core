class Libmrss < Formula
  desc "C library for RSS files or streams"
  homepage "https://github.com/bakulf/libmrss"
  url "https://github.com/bakulf/libmrss/archive/refs/tags/0.19.4.tar.gz"
  sha256 "28022247056b04ca3f12a9e21134d42304526b2a67b7d6baf139e556af1151c6"
  license "LGPL-2.1-or-later"
  head "https://github.com/bakulf/libmrss.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1ddaf562eb1af3116ad668cffb207cfb9247e8f4603eeeadcef980532562ab48"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "libnxml"

  uses_from_macos "curl"

  def install
    # need NEWS file for build
    touch "NEWS"

    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <mrss.h>

      int main() {
        mrss_t *rss;
        mrss_error_t error;
        mrss_item_t *item;
        const char *url = "https://raw.githubusercontent.com/git/git.github.io/master/feed.xml";

        error = mrss_parse_url(url, &rss);
        if (error) {
            printf("Error parsing RSS feed: %s\\n", mrss_strerror(error));
            return 1;
        }

        for (item = rss->item; item; item = item->next) {
            printf("Title: %s\\n", item->title);
        }

        mrss_free(rss);

        return 0;
      }
    C

    flags = shell_output("pkgconf --cflags --libs mrss").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    assert_match "Title: {{ post.title | xml_escape}}", shell_output("./test")
  end
end
