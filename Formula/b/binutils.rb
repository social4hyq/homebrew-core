class Binutils < Formula
  desc "GNU binary tools for native development"
  homepage "https://www.gnu.org/software/binutils/binutils.html"
  url "https://ftpmirror.gnu.org/gnu/binutils/binutils-2.47.tar.bz2"
  mirror "https://ftp.gnu.org/gnu/binutils/binutils-2.47.tar.bz2"
  sha256 "3068128c75cda9f898ccb4211d360246e8e195ffcc9dfb655b23ae23a54800e8"
  license all_of: ["GPL-2.0-or-later", "GPL-3.0-or-later", "LGPL-2.0-or-later", "LGPL-3.0-only"]
  revision 2
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "da58437e3109fdedc63c58edbcce3f87a9ebc6bdaf562003e8a5658a10b1c6d1"
  end

  keg_only :shadowed_by_macos, "Apple's CLT provides the same tools"

  depends_on "pkgconf" => :build
  depends_on "zstd"

  uses_from_macos "bison" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  conflicts_with "llvm-gcc-compat", because: "both install `ld` binaries"

  skip_clean "etc/ld.so.conf"

  link_overwrite "bin/dwp"

  # ═══════════════════════════════════════════════════════════════════
  # HarmonyOS patches
  #
  #   0001: Give the linked output the `.codesign` section that OpenHarmony
  #         requires before it will execute or dlopen an ELF.  The signer is
  #         ohos-bst-light's `selfsign` (0BSD), vendored into `ld` and called
  #         in-process, so nothing is spawned per link.  Signing is on by
  #         default and `--no-code-sign` turns it off.
  #
  #   0002: Keep the zero-length terminator at the end of the linked
  #         `.eh_frame`.  GNU ld normally keeps the one from crtend.o, but on
  #         OpenHarmony the C library's crtn.o is linked after it and has no
  #         terminator of its own, so bfd dropped the last one; readers of the
  #         section (libgcc's frame registration, e.g. on the way into a C++
  #         program) then walked past its end and crashed.
  # ═══════════════════════════════════════════════════════════════════

  patch do
    file "Patches/binutils/0001-ohos-code-sign.patch"
  end

  patch do
    file "Patches/binutils/0002-ohos-eh-frame-terminator.patch"
  end

  def install
    # Workaround https://sourceware.org/bugzilla/show_bug.cgi?id=28909
    touch "gas/doc/.dirstamp", mtime: Time.utc(2022, 1, 1)
    make_args = OS.mac? ? [] : ["MAKEINFO=true"] # for gprofng

    args = %W[
      --enable-deterministic-archives
      --infodir=#{info}
      --mandir=#{man}
      --disable-werror
      --enable-interwork
      --enable-multilib
      --enable-64-bit-bfd
      --enable-plugins
      --enable-targets=all
      --with-system-zlib
      --with-zstd
      --disable-nls
    ]
    # Skip Ada compiler probe: the test compilation forks endlessly on
    # OpenHarmony where clang lacks Ada support.
    system "./configure", *args, *std_configure_args,
           "acx_cv_cc_gcc_supports_ada=no"
    system "make", *make_args
    system "make", "install", *make_args

    if OS.mac?
      Dir["#{bin}/*"].each do |f|
        bin.install_symlink f => "g" + File.basename(f)
      end
    else
      # Reduce the size of the bottle.
      bin_files = bin.children.select(&:elf?)
      system "strip", *bin_files, *lib.glob("*.a")
    end

    # Allow ld to find brew glibc. A broken symlink falls back to /etc/ld.so.conf
    (prefix/"etc").install_symlink etc/"ld.so.conf" if OS.linux?
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/strings #{bin}/strings")
    assert_predicate prefix/"etc/ld.so.conf", :symlink? if OS.linux?

    # Linking signs the output for OpenHarmony by default; --no-code-sign
    # turns that off.
    (testpath/"hello.c").write <<~C
      int main(void)
      {
        return 0;
      }
    C
    system ENV.cc, "--ld-path=#{bin}/ld", "-o", "hello", "hello.c"
    assert_match ".codesign", shell_output("#{bin}/readelf -S hello")
    system ENV.cc, "--ld-path=#{bin}/ld", "-Wl,--no-code-sign", "-o", "hello-unsigned", "hello.c"
    refute_match ".codesign", shell_output("#{bin}/readelf -S hello-unsigned")
    system "./hello"
  end
end
