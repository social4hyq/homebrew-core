class Kyua < Formula
  desc "Testing framework for infrastructure software"
  homepage "https://github.com/freebsd/kyua"
  url "https://github.com/freebsd/kyua/releases/download/kyua-0.14.1/kyua-0.14.1.tar.gz"
  sha256 "3caf30a7e316f4f21c32e1c419ec80371fe113e3eed10ba1db9e6efc7ee15ecb"
  license "BSD-3-Clause"
  revision 1
  head "https://github.com/freebsd/kyua.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7be010b4d4a4f87e0819786fe234769ac55c3bcd2501e5830ce6daf5f79e9877"
  end

  depends_on "pkgconf" => [:build, :test]
  depends_on "atf"
  depends_on "lua"
  depends_on "lutok"

  uses_from_macos "sqlite"

  def install
    ENV.append "CPPFLAGS", "-I#{Formula["lua"].opt_include}/lua"

    system "./configure", *std_configure_args,
                          "--disable-silent-rules",
                          "--enable-atf"
    system "make"
    ENV.deparallelize
    system "make", "install"
  end

  test do
    kyuafile = testpath/"Kyuafile"
    kyuafile.write <<~EOF
      syntax(2)

      test_suite("sanity_check")

      atf_test_program{name="atf_test"}
      plain_test_program{name="plain_test"}
      tap_test_program{name="tap_test"}
    EOF

    atf_test_c = testpath/"atf_test.c"
    atf_test_c.write <<~EOF
      #include <atf-c.h>

      ATF_TC_WITHOUT_HEAD(tc1);
      ATF_TC_BODY(tc1, tc)
      {
        int i = 2;
        ATF_REQUIRE_EQ(i * 2, 4);
      }

      ATF_TP_ADD_TCS(tp)
      {
        ATF_TP_ADD_TC(tp, tc1);

        return atf_no_error();
      }
    EOF

    flags = shell_output("pkgconf --cflags --libs atf-c").chomp.split
    system ENV.cc, atf_test_c, "-o", "atf_test", *flags

    plain_test = testpath/"plain_test"
    plain_test.write <<~EOF
      #!/bin/sh
      echo "this is a plain test that always passes"
    EOF
    plain_test.chmod(0555)

    tap_test = testpath/"tap_test"
    tap_test.write <<~EOF
      #!/bin/sh
      echo "1..2"
      echo "ok 1"
      echo "not ok 2 # SKIP: demonstrates that not ok + SKIP => does not fail"
    EOF
    tap_test.chmod(0555)

    system bin/"kyua", "test", "-k", kyuafile
  end
end
