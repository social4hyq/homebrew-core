class Libpaper < Formula
  desc "Library for handling paper characteristics"
  homepage "https://github.com/rrthomas/libpaper"
  url "https://github.com/rrthomas/libpaper/releases/download/v2.3.0/libpaper-2.3.0.tar.gz"
  sha256 "882b1c7636052fc9a318caa20292b35616b588824b70e7053018262b29b1409a"
  license "LGPL-2.1-or-later"
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "81edbd440a424c944676c42bf67fc28f648eaf6370cf31897e61efc3cb6e4b74"
  end

  depends_on "help2man" => :build

  def install
    system "./configure", *std_configure_args, "--sysconfdir=#{etc}"
    system "make", "install"
  end

  test do
    assert_match "A4: 210x297 mm", shell_output("#{bin}/paper --all")
    assert_match "paper #{version}", shell_output("#{bin}/paper --version")

    (testpath/"test.c").write <<~C
      #include <paper.h>
      int main()
      {
        enum paper_unit unit;
        int ret = paperinit();
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lpaper", "-o", "test"
    system "./test"
  end
end
