class Patchelf < Formula
  desc "Modify dynamic ELF executables"
  homepage "https://github.com/NixOS/patchelf"
  url "https://github.com/NixOS/patchelf/releases/download/0.19.1/patchelf-0.19.1.tar.bz2"
  sha256 "2cce01de93653829f6ab68a20c2ec275e1c00a946110704a27e928d2e6e88716"
  license "GPL-3.0-or-later"
  revision 1

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "62e15560ab8e9b209659f270c2d5982b8ee92a5d70b1dcc47dcf1877cd9143eb"
  end

  head do
    url "https://github.com/NixOS/patchelf.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  def install
    if OS.linux?
      # Fix ld.so path and rpath
      # see https://github.com/Homebrew/linuxbrew-core/pull/20548#issuecomment-672061606
      ENV["HOMEBREW_RPATH_PATHS"] = nil
    end

    system "./bootstrap.sh" if build.head?
    system "./configure", "--prefix=#{prefix}",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules"
    system "make", "install"
  end

  test do
    cp test_fixtures("elf/hello"), testpath
    assert_equal "/lib64/ld-linux-x86-64.so.2\n", shell_output("#{bin}/patchelf --print-interpreter hello")
    assert_equal "libc.so.6\n", shell_output("#{bin}/patchelf --print-needed hello")
    assert_equal "\n", shell_output("#{bin}/patchelf --print-rpath hello")
    assert_empty shell_output("#{bin}/patchelf --set-rpath /usr/local/lib hello")
    assert_equal "/usr/local/lib\n", shell_output("#{bin}/patchelf --print-rpath hello")
  end
end
