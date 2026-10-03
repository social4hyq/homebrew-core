class Qemu < Formula
  desc "Generic machine emulator and virtualizer"
  homepage "https://www.qemu.org/"
  url "https://download.qemu.org/qemu-11.1.2.tar.xz"
  sha256 "731b5681e4bb18be313231579b8efd0296c5b015fa36dc533874b639ba838016"
  license "GPL-2.0-only"
  revision 2
  compatibility_version 1
  head "https://gitlab.com/qemu-project/qemu.git", branch: "master"

  livecheck do
    url "https://www.qemu.org/download/"
    regex(/href=.*?qemu[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/qemu-v11.1.2-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "69c0b79e32c23eca86a6bce33057a398698ff811273ca624ffe67b59fa91a085"
  end

  depends_on "bison" => :build # >= 3.0
  depends_on "libtool" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "python-setuptools" => :build
  depends_on "python@3.14" => :build # keep aligned with meson
  depends_on "spice-protocol" => :build

  depends_on "capstone"
  depends_on "curl"
  depends_on "dtc"
  depends_on "glib"
  depends_on "gnutls"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "libslirp"
  depends_on "libssh"
  depends_on "libusb"
  depends_on "lzo"
  depends_on "musl-compat"
  depends_on "ncurses"
  depends_on "pixman"
  depends_on "snappy"
  depends_on "zstd"

  uses_from_macos "flex" => :build
  uses_from_macos "bzip2"

  on_linux do
    depends_on "attr"
    depends_on "libcap-ng"
    depends_on "libseccomp"
    depends_on "libxkbcommon"
    depends_on "zlib-ng-compat"
  end

  patch do
    file "Patches/qemu/0001-use-automatic-imx8-memory-map-tables.patch"
  end

  patch do
    file "Patches/qemu/0002-guard-unavailable-madvise-values.patch"
  end

  patch do
    file "Patches/qemu/0003-adapt-ohos-syscall-types.patch"
  end

  patch do
    file "Patches/qemu/0004-provide-missing-host-signal-and-tty-functions.patch"
  end

  patch do
    file "Patches/qemu/0005-use-ohos-virtio-headers.patch"
  end

  deny_network_access!

  def install
    ENV["LIBTOOL"] = "glibtool"
    # OHOS SDK keyctl and USB headers retain kernel-only __user annotations.
    ENV.append "CFLAGS", "-D__user="
    # OHOS libc omits the POSIX message queue functions used by linux-user.
    ENV.append "LDFLAGS", "-L#{formula_opt_lib("musl-compat")} -lmusl_compat"

    # Remove wheels unless explicitly permitted. Currently this:
    # * removes `meson` so that brew `meson` is always used
    # * keeps `pycotap` and `qemu_qmp` which are pure-python "none-any" wheels (allowed in homebrew/core)
    rm(Dir["python/wheels/*"] - Dir["python/wheels/{pycotap,qemu_qmp}-*-none-any.whl"])

    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cc=#{ENV.cc}
      --disable-bsd-user
      --disable-download
      --disable-guest-agent
      --enable-slirp
      --enable-capstone
      --enable-curses
      --enable-fdt=system
      --enable-libssh
      --disable-vde
      --enable-virtfs
      --enable-zstd
      --extra-cflags=-DNCURSES_WIDECHAR=1
      --disable-sdl
    ]

    # Sharing Samba directories in QEMU requires the samba.org smbd which is
    # incompatible with the macOS-provided version. This will lead to
    # silent runtime failures, so we set it to a Homebrew path in order to
    # obtain sensible runtime errors. This will also be compatible with
    # Samba installations from external taps.
    args << "--smbd=#{HOMEBREW_PREFIX}/sbin/samba-dot-org-smbd"

    # The arm64 HVF backend needs the macOS 15 SDK for its EL2 sysregs and vGIC
    args << "--disable-hvf" if OS.mac? && Hardware::CPU.arm? && MacOS.version <= :sonoma

    # Starting in Golden Gate, ParavirtualizedGraphics.framework is present but
    # largely unusable. Remove once QEMU configure script is able to correctly
    # handle this.
    #
    # See https://patchew.org/QEMU/20260826203700.39057-1-dude@angrygoose.dev/.
    args << "--disable-pvg" if OS.mac? && MacOS.version >= :golden_gate

    args += if OS.mac?
      ["--disable-gtk", "--enable-cocoa"]
    else
      ["--disable-gtk"]
    end

    system "./configure", *args
    system "make", "V=1", "install"
  end

  test do
    archs = %w[
      aarch64 alpha arm avr hppa i386 loongarch64 m68k microblaze mips
      mips64 mips64el mipsel or1k ppc ppc64 riscv32 riscv64 rx
      s390x sh4 sh4eb sparc sparc64 tricore x86_64 xtensa xtensaeb
    ]
    archs.each do |guest_arch|
      assert_match version.to_s, shell_output("#{bin}/qemu-system-#{guest_arch} --version")
    end

    system bin/"qemu-img", "create", "-f", "qcow2", "test.qcow2", "1440k"
    assert_match "file format: qcow2", shell_output("#{bin}/qemu-img info test.qcow2")

    system bin/"qemu-img", "convert", "-O", "raw", "test.qcow2", "test.img"
    assert_match "file format: raw", shell_output("#{bin}/qemu-img info test.img")

    # On macOS, verify that we haven't clobbered the signature on the qemu-system-x86_64 binary
    if OS.mac?
      output = shell_output("codesign --verify --verbose #{bin}/qemu-system-x86_64 2>&1")
      assert_match "valid on disk", output
      assert_match "satisfies its Designated Requirement", output
    end
  end
end
