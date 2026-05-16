class Utimer < Formula
  desc "Multifunction timer tool"
  homepage "https://launchpad.net/utimer"
  url "https://launchpad.net/utimer/0.4/0.4/+download/utimer-0.4.tar.gz"
  sha256 "07a9d28e15155a10b7e6b22af05c84c878d95be782b6b0afaadec2f7884aa0f7"
  license "GPL-3.0-or-later"
  revision 1

  livecheck do
    skip "No longer developed or maintained"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "66b8b3d9c12147ca47caf503a9f4ac720d00af168b5a80ce4d7f33d7df8785db"
  end

  depends_on "gettext" => :build
  depends_on "intltool" => :build
  depends_on "pkgconf" => :build
  depends_on "glib"

  uses_from_macos "perl" => :build

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "perl-xml-parser" => :build
  end

  def install
    # Work around /usr/bin/ld: timer.o:(.bss+0x0): multiple definition of `ut_config'
    ENV.append_to_cflags "-fcommon" if OS.linux?
    # Fix compile with newer Clang. Project is no longer maintained so cannot be fixed upstream.
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_match "Elapsed Time:", shell_output("#{bin}/utimer -t 0ms")
  end
end
