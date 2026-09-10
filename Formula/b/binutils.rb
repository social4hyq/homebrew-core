class Binutils < Formula
  desc "GNU binary tools for native development"
  homepage "https://www.gnu.org/software/binutils/binutils.html"
  url "https://ftpmirror.gnu.org/gnu/binutils/binutils-2.47.tar.bz2"
  mirror "https://ftp.gnu.org/gnu/binutils/binutils-2.47.tar.bz2"
  sha256 "3068128c75cda9f898ccb4211d360246e8e195ffcc9dfb655b23ae23a54800e8"
  license all_of: ["GPL-2.0-or-later", "GPL-3.0-or-later", "LGPL-2.0-or-later", "LGPL-3.0-only"]
  revision 1
  compatibility_version 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8919f27475e3a2c55cb22b11a91b0d5143e2a4aab3803a9850660c93ae17caa1"
  end

  keg_only "it shadows the host toolchain"

  depends_on "pkgconf" => :build
  depends_on "zstd"

  uses_from_macos "bison" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  skip_clean "etc/ld.so.conf"

  link_overwrite "bin/dwp"

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
  end
end
