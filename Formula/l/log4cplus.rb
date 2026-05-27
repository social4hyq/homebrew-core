class Log4cplus < Formula
  desc "Logging Framework for C++"
  homepage "https://sourceforge.net/p/log4cplus/wiki/Home/"
  url "https://downloads.sourceforge.net/project/log4cplus/log4cplus-stable/2.1.2/log4cplus-2.1.2.tar.xz"
  sha256 "fbdabb4ef734fe1cc62169b23f0b480cc39127ac7b09b810a9c1229490d67e9e"
  license all_of: ["Apache-2.0", "BSD-2-Clause"]

  livecheck do
    url :stable
    regex(/url=.*?log4cplus-stable.*?log4cplus[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b31b5f5949d7071143c0e5df9ae920652e7b648a88a7a3fa598adda77c947a0d"
  end

  depends_on "pkgconf" => [:build, :test]

  def install
    ENV.cxx11
    system "./configure", *std_configure_args.reject { |s| s["--disable-debug"] }
    system "make", "install"
  end

  test do
    # https://github.com/log4cplus/log4cplus/blob/65e4c3/docs/examples.md
    (testpath/"test.cpp").write <<~CPP
      #include <log4cplus/logger.h>
      #include <log4cplus/loggingmacros.h>
      #include <log4cplus/configurator.h>
      #include <log4cplus/initializer.h>

      int main()
      {
        log4cplus::Initializer initializer;
        log4cplus::BasicConfigurator config;
        config.configure();

        log4cplus::Logger logger = log4cplus::Logger::getInstance(
          LOG4CPLUS_TEXT("main"));
        LOG4CPLUS_WARN(logger, LOG4CPLUS_TEXT("Hello, World!"));
        return 0;
      }
    CPP

    pkgconf_flags = shell_output("pkgconf --cflags --libs log4cplus").chomp.split
    system ENV.cxx, "-std=c++11", "-o", "test", "test.cpp", *pkgconf_flags
    assert_match "Hello, World!", shell_output("./test")
  end
end
