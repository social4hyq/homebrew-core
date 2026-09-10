class Apr < Formula
  desc "Apache Portable Runtime library"
  homepage "https://apr.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=apr/apr-1.7.6.tar.bz2"
  mirror "https://archive.apache.org/dist/apr/apr-1.7.6.tar.bz2"
  sha256 "49030d92d2575da735791b496dc322f3ce5cff9494779ba8cc28c7f46c5deb32"
  license "Apache-2.0"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "899011f0c9ec0c26974ee80018deffe1603d1c7d9c6df3cd71f314fd13426bc7"
  end

  keg_only :provided_by_macos, "Apple's CLT provides apr"

  uses_from_macos "libxcrypt"

  on_linux do
    depends_on "util-linux"
  end

  def install
    # https://bz.apache.org/bugzilla/show_bug.cgi?id=57359
    # The internal libtool throws an enormous strop if we don't do...
    ENV.deparallelize

    system "./configure", *std_configure_args
    system "make", "install"

    rm lib.glob("*.{la,exp}")

    # No need for this to point to the versioned path.
    inreplace bin/"apr-#{version.major}-config", prefix, opt_prefix

    # Avoid references to the Homebrew shims directory
    # NOTE: libtool may not contain shims path on OpenHarmony
    inreplace prefix/"build-#{version.major}/libtool", Superenv.shims_path, "/usr/bin" if OS.linux? && File.read(prefix/"build-#{version.major}/libtool").include?(Superenv.shims_path)
  end

  test do
    assert_match opt_prefix.to_s, shell_output("#{bin}/apr-#{version.major}-config --prefix")
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <apr-#{version.major}/apr_version.h>
      int main() {
        printf("%s", apr_version_string());
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lapr-#{version.major}", "-o", "test"
    assert_equal version.to_s, shell_output("./test")
  end
end
