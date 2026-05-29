class Libcss < Formula
  desc "CSS parser and selection engine"
  homepage "https://www.netsurf-browser.org/projects/libcss/"
  url "https://download.netsurf-browser.org/libs/releases/libcss-0.9.2-src.tar.gz"
  sha256 "2df215bbec34d51d60c1a04b01b2df4d5d18f510f1f3a7af4b80cddb5671154e"
  license "MIT"
  head "git://git.netsurf-browser.org/libcss.git", branch: "master"

  livecheck do
    url :homepage
    regex(/href=.*?libcss[._-]v?(\d+(?:\.\d+)+)[._-]src\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f659d860e334dbf5e2692dda18b25bf779d562150dc4105f6d42234f23c904cb"
  end

  depends_on "netsurf-buildsystem" => :build
  depends_on "pkgconf" => [:build, :test]
  depends_on "libparserutils"
  depends_on "libwapcaplet"

  def install
    args = %W[
      NSSHARED=#{Formula["netsurf-buildsystem"].opt_pkgshare}
      PREFIX=#{prefix}
    ]

    system "make", "install", "COMPONENT_TYPE=lib-shared", *args
  end

  test do
    (testpath/"test.css").write <<~CSS
      body {
        background-color: #FFFFFF;
      }
    CSS

    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <libcss/libcss.h>

      int main() {
        css_error error;
        css_select_ctx *ctx;

        error = css_select_ctx_create(&ctx);
        if (error != CSS_OK) {
          return 1;
        }

        css_select_ctx_destroy(ctx);
        return 0;
      }
    C

    flags = shell_output("pkgconf --cflags --libs libcss").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
