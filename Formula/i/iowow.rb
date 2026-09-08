class Iowow < Formula
  desc "C utility library and persistent key/value storage engine"
  homepage "https://github.com/Softmotions/iowow"
  url "https://github.com/Softmotions/iowow/archive/refs/tags/v1.5.2.tar.gz"
  sha256 "24b91edcc69a48a752b2a1892a0b935e980afb8a04eb659c699e77d29253ab61"
  license "MIT"
  head "https://github.com/Softmotions/iowow.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "75dcdc51d196fb0998b10f8feedf7c7af06229542204807b6385d62d6b40a684"
  end

  depends_on "pkgconf" => :build

  def install
    ENV["BUILD_TYPE"] = "Release"
    system "./build.sh", "--prefix=#{prefix}", "--libdir=lib", "--includedir=include",
                         "--pkgconfdir=lib/pkgconfig", "--jobs=#{ENV.make_jobs}",
                         "-DIOWOW_BUILD_SHARED_LIBS=1", "--install"

    # Upstream also installs a copy of the source tree.
    rm_r pkgshare
  end

  test do
    (testpath/"test.c").write <<~'EOS'
      #include <iowow/iwkv.h>
      #include <stdio.h>

      int main(void) {
        IWKV_OPTS opts = { .path = "test.db", .oflags = IWKV_TRUNC };
        IWKV iwkv;
        IWDB db;
        if (iwkv_open(&opts, &iwkv) || iwkv_db(iwkv, 1, 0, &db)) return 1;

        IWKV_val key = { .data = "foo", .size = 3 };
        IWKV_val val = { .data = "bar", .size = 3 };
        if (iwkv_put(db, &key, &val, 0)) return 1;

        val.data = 0;
        val.size = 0;
        if (iwkv_get(db, &key, &val)) return 1;
        printf("%.*s => %.*s\n", (int) key.size, (char *) key.data,
               (int) val.size, (char *) val.data);

        iwkv_val_dispose(&val);
        iwkv_close(&iwkv);
        return 0;
      }
    EOS

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-liowow", "-o", "test"
    assert_equal "foo => bar\n", shell_output("./test")
  end
end
