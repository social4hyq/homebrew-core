require File.expand_path("../../Abstract/portable-formula", __dir__)

class PortableCurl < PortableFormula
  desc "Get a file from an HTTP, HTTPS or FTP server"
  homepage "https://curl.se"
  # Don't forget to update both instances of the version in the GitHub mirror URL.
  url "https://curl.se/download/curl-8.22.0.tar.bz2"
  mirror "https://github.com/curl/curl/releases/download/curl-8_22_0/curl-8.22.0.tar.bz2"
  mirror "http://fresh-center.net/linux/www/curl-8.22.0.tar.bz2"
  mirror "http://fresh-center.net/linux/www/legacy/curl-8.22.0.tar.bz2"
  sha256 "5d956a6a22b3c279f50c421ee5d3c9e9d660cb6f115dcf881b579e952130549c"
  license "curl"

  livecheck do
    url "https://curl.se/download/"
    regex(/href=.*?curl[._-]v?(.*?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5d768fb5f8c4d06113f46fbd4a0922c729a2586b045ee2157e1fbdaa2b933c0b"
  end

  head do
    url "https://github.com/curl/curl.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "portable-openssl"
  depends_on "portable-zlib"

  def install
    tag_name = "curl-#{version.to_s.tr(".", "_")}"
    if build.stable? && stable.mirrors.grep(%r{\Ahttps?://(www\.)?github\.com/}).first.exclude?(tag_name)
      odie "Tag name #{tag_name} is not found in the GitHub mirror URL! " \
           "Please make sure the URL is correct."
    end

    system "autoreconf", "--force", "--install", "--verbose" if build.head?

    args = %W[
      --disable-silent-rules
      --with-ssl=#{Formula["portable-openssl"].opt_prefix}
      --with-zlib=#{Formula["portable-zlib"].opt_prefix}
      --with-ca-bundle=/etc/ssl/certs/cacert.pem
      --with-ca-path=/etc/ssl/certs
      --enable-static
      --disable-shared
      --without-libpsl
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <curl/curl.h>
      #include <stdio.h>

      int main(void) {
        CURL *curl = curl_easy_init();
        if (curl) {
          printf("curl init success\\n");
          curl_easy_cleanup(curl);
          return 0;
        }
        return 1;
      }
    C

    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}", "-lcurl", "-L#{Formula["portable-openssl"].opt_lib}",
      "-lssl", "-lcrypto", "-L#{Formula["portable-zlib"].opt_lib}", "-lz", "-o", "test"

    assert_match "curl init success", shell_output("./test")
  end
end
