class NetsurfBuildsystem < Formula
  desc "Makefiles shared by NetSurf projects"
  homepage "https://www.netsurf-browser.org/"
  url "https://download.netsurf-browser.org/libs/releases/buildsystem-1.10.tar.gz"
  sha256 "3d3e39d569e44677c4b179129bde614c65798e2b3e6253160239d1fd6eae4d79"
  license "MIT"
  head "git://git.netsurf-browser.org/buildsystem.git", branch: "master"

  livecheck do
    url "https://download.netsurf-browser.org/libs/releases/"
    regex(/href=.*?buildsystem[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e3fcae6e79e5db48e15d1cdc16585a854f8584b188c1531bc435bc01ebf2dbb9"
  end

  def install
    system "make", "install", "PREFIX=#{prefix}"

    # Consistently replace /usr/local with HOMEBREW_PREFIX for reproducible bottles
    inreplace pkgshare/"makefiles/Makefile.tools", "/usr/local", HOMEBREW_PREFIX
  end

  test do
    (testpath/"src").mkpath

    (testpath/"Makefile").write <<~MAKE
      COMPONENT := hello
      COMPONENT_VERSION := 0.1.0
      COMPONENT_TYPE ?= binary
      include $(NSSHARED)/makefiles/Makefile.tools
      include $(NSBUILD)/Makefile.top
      INSTALL_ITEMS := $(INSTALL_ITEMS) /bin:$(BUILDDIR)/$(COMPONENT)
    MAKE

    (testpath/"src/Makefile").write <<~MAKE
      DIR_SOURCES := main.c
      include $(NSBUILD)/Makefile.subdir
    MAKE

    (testpath/"src/main.c").write <<~C
      #include <stdio.h>
      int main() {
        printf("Hello, world!");
        return 0;
      }
    C

    args = %W[
      NSSHARED=#{pkgshare}
      PREFIX=#{testpath}
    ]

    system "make", "install", *args
    assert_equal "Hello, world!", shell_output(testpath/"bin/hello")
  end
end
