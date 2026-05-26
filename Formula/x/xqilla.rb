class Xqilla < Formula
  desc "XQuery and XPath 2 command-line interpreter"
  homepage "https://xqilla.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/xqilla/XQilla-2.3.4.tar.gz"
  sha256 "292631791631fe2e7eb9727377335063a48f12611d641d0296697e0c075902eb"
  license "Apache-2.0"
  revision 1

  livecheck do
    url :stable
    regex(%r{url=.*?/XQilla[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "58c35b13296f0fa051679d9c608f67462705d21d4e53c3973f31004f8da705ec"
  end

  depends_on "xerces-c"

  def install
    ENV.cxx11

    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", "--with-xerces=#{HOMEBREW_PREFIX}", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <xqilla/xqilla-simple.hpp>

      int main(int argc, char *argv[]) {
        XQilla xqilla;
        AutoDelete<XQQuery> query(xqilla.parse(X("1 to 100")));
        AutoDelete<DynamicContext> context(query->createDynamicContext());
        Result result = query->execute(context);
        Item::Ptr item;
        while(item == result->next(context)) {
          std::cout << UTF8(item->asString(context)) << std::endl;
        }
        return 0;
      }
    CPP
    system ENV.cxx, "-std=c++11", testpath/"test.cpp", "-o", testpath/"test",
                    "-I#{include}", "-I#{Formula["xerces-c"].opt_include}",
                    "-L#{lib}", "-lxqilla",
                    "-L#{Formula["xerces-c"].opt_lib}", "-lxerces-c"
    system testpath/"test"
  end
end
