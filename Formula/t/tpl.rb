class Tpl < Formula
  desc "Store and retrieve binary data in C"
  homepage "https://troydhanson.github.io/tpl/"
  url "https://github.com/troydhanson/tpl/archive/refs/tags/v1.6.1.tar.gz"
  sha256 "0b3750bf62f56be4c42f83c89d8449b24f1c5f1605a104801d70f2f3c06fb2ff"
  license "BSD-1-Clause"
  head "https://github.com/troydhanson/tpl.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b1fd541788a0c8f322bc79997337262e8bba0a8566233cf87cb7235ea8e6bee2"
  end

  deprecate! date: "2025-12-11", because: :repo_archived
  disable! date: "2026-12-11", because: :repo_archived

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules",
                          *std_configure_args.reject { |s| s["--disable-debug"] }
    system "make", "install"
  end

  test do
    (testpath/"store.c").write <<~C
      #include <tpl.h>

      int main(int argc, char *argv[]) {
          tpl_node *tn;
          int id = 0;
          char *name, *names[] = { "Alice", "Bob", "Charlie" };

          tn = tpl_map("A(is)", &id, &name);

          for(name = names[0]; id < 3; name = names[++id]) {
              tpl_pack(tn,1);
          }

          tpl_dump(tn, TPL_FILE, "users.tpl");
          tpl_free(tn);
      }
    C

    (testpath/"load.c").write <<~C
      #include <stdio.h>
      #include <stdlib.h>
      #include <tpl.h>

      int main(int argc, char *argv[]) {
          tpl_node *tn;
          int id;
          char *name;

          tn = tpl_map("A(is)", &id, &name);
          tpl_load(tn, TPL_FILE, "users.tpl");

          while (tpl_unpack(tn, 1) > 0) {
              printf("%d: %s\\n", id, name);
              free(name);
          }
          tpl_free(tn);
      }
    C

    system ENV.cc, "store.c", "-I#{include}", "-L#{lib}", "-ltpl", "-o", "store"
    system ENV.cc, "load.c", "-I#{include}", "-L#{lib}", "-ltpl", "-o", "load"

    expected = <<~EOS
      0: Alice
      1: Bob
      2: Charlie
    EOS

    system "./store"
    assert_equal expected, shell_output("./load")
  end
end
