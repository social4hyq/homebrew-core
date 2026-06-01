class Npth < Formula
  desc "New GNU portable threads library"
  homepage "https://gnupg.org/"
  url "https://gnupg.org/ftp/gcrypt/npth/npth-1.8.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/npth/npth-1.8.tar.bz2"
  sha256 "8bd24b4f23a3065d6e5b26e98aba9ce783ea4fd781069c1b35d149694e90ca3e"
  license "LGPL-2.1-or-later"

  livecheck do
    url "https://gnupg.org/ftp/gcrypt/npth/"
    regex(/href=.*?npth[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4454f41905bd78cca73282a3b8885fa00fb8a7d11e71d4dcc97ec034f77c2aa9"
  end

  def install
    ENV["ac_cv_search_pthread_cancel"] = "none required"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <npth.h>

      void* thread_function(void *arg) {
          printf("Hello from nPth thread!\\n");
          return NULL;
      }

      int main() {
          npth_t thread_id;
          int status;

          status = npth_init();
          if (status != 0) {
              fprintf(stderr, "Failed to initialize nPth.\\n");
              return 1;
          }

          status = npth_create(&thread_id, NULL, thread_function, NULL);
          npth_join(thread_id, NULL);
          return 0;
      }

    C
    system ENV.cc, "test.c", "-L#{lib}", "-lnpth", "-o", "test"
    assert_match "Hello from nPth thread!", shell_output("./test")
  end
end
