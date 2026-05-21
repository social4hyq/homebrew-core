class Libesedb < Formula
  desc "Library and tools for Extensible Storage Engine (ESE) Database files"
  homepage "https://github.com/libyal/libesedb"
  url "https://github.com/libyal/libesedb/releases/download/20240420/libesedb-experimental-20240420.tar.gz"
  sha256 "07250741dff8a1ea1f5e38c02f1b9a1ae5e9fa52d013401067338842883a5b9f"
  license "LGPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3fc8486103cb89a1a730264b1be1eba2b66dd9e0d892666d5473fd58a1d3b57d"
  end

  depends_on "pkgconf" => :test

  def install
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/esedbinfo -V")

    (testpath/"test.c").write <<~C
      #include <libesedb.h>
      #include <stdio.h>

      int main() {
        printf("libesedb version: %d\\n", LIBESEDB_VERSION);
        return 0;
      }
    C

    flags = shell_output("pkgconf --cflags --libs libesedb").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags
    assert_match "libesedb version: #{version}", shell_output("./test")
  end
end
