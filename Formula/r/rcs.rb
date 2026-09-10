class Rcs < Formula
  desc "GNU revision control system"
  homepage "https://www.gnu.org/software/rcs/"
  url "https://ftpmirror.gnu.org/gnu/rcs/rcs-5.10.1.tar.lz"
  mirror "https://ftp.gnu.org/gnu/rcs/rcs-5.10.1.tar.lz"
  sha256 "43ddfe10724a8b85e2468f6403b6000737186f01e60e0bd62fde69d842234cc5"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0a88fb79e82fd8e291c3baab160bc867a450740ac26acb3373dbf90f63c472b6"
  end

  uses_from_macos "ed" => :build

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-incompatible-function-pointer-types" if DevelopmentTools.clang_build_version >= 1500

    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"merge", "--version"
  end
end
