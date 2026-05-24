class Log4cpp < Formula
  desc "Configurable logging for C++"
  homepage "https://log4cpp.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/log4cpp/log4cpp-1.1.x%20%28new%29/log4cpp-1.1/log4cpp-1.1.6.tar.gz"
  sha256 "a036bc6bd6044479e6c456de7edd042b060ea5c843e47beb75f59baea9b20e3a"
  license "LGPL-2.1-or-later"

  livecheck do
    url :stable
    regex(%r{url=.*?/log4cpp[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c59c8cbde4803b267a2caec54fd063f3b2668655de5c0bdd48e704057fee374a"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    ENV.cxx11
    args = []
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"log4cpp.cpp").write <<~CPP
      #include <log4cpp/Category.hh>
      #include <log4cpp/PropertyConfigurator.hh>
      #include <log4cpp/OstreamAppender.hh>
      #include <log4cpp/Priority.hh>
      #include <log4cpp/BasicLayout.hh>
      #include <iostream>
      #include <memory>

      int main(int argc, char* argv[]) {
        log4cpp::OstreamAppender* osAppender = new log4cpp::OstreamAppender("osAppender", &std::cout);
        osAppender->setLayout(new log4cpp::BasicLayout());

        log4cpp::Category& root = log4cpp::Category::getRoot();
        root.addAppender(osAppender);
        root.setPriority(log4cpp::Priority::INFO);

        root.info("This is an informational log message");

        // Clean up
        root.removeAllAppenders();
        log4cpp::Category::shutdown();

        return 0;
      }
    CPP
    system ENV.cxx, "log4cpp.cpp", "-L#{lib}", "-llog4cpp", "-o", "log4cpp"
    system "./log4cpp"
  end
end
