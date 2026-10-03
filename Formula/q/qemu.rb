class Qemu < Formula
  desc "Generic machine emulator and virtualizer"
  homepage "https://www.qemu.org/"
  url "https://download.qemu.org/qemu-11.1.2.tar.xz"
  sha256 "731b5681e4bb18be313231579b8efd0296c5b015fa36dc533874b639ba838016"
  license "GPL-2.0-only"
  revision 3
  compatibility_version 1
  head "https://gitlab.com/qemu-project/qemu.git", branch: "master"

  livecheck do
    url "https://www.qemu.org/download/"
    regex(/href=.*?qemu[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/qemu-v11.1.2-r5"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "deeebbbcdc256bc7260d21f05c90da1f7fcde1cdad0cb36e41046bf222bbf4a6"
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

  patch do
    file "Patches/qemu/0006-use-syscalls-for-posix-message-queues.patch"
  end

  deny_network_access!

  def install
    ENV["LIBTOOL"] = "glibtool"
    # OHOS SDK keyctl and USB headers retain kernel-only __user annotations.
    ENV.append "CFLAGS", "-D__user="

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

    system bin/"qemu-io", "-f", "qcow2", "-c", "write -P 0x5a 0 4096", "test.qcow2"
    system bin/"qemu-img", "convert", "-O", "raw", "test.qcow2", "test.img"
    assert_match "file format: raw", shell_output("#{bin}/qemu-img info test.img")
    assert_equal "Z" * 4096, (testpath/"test.img").binread(4096)

    require "socket"
    disk = (testpath/"test.img").binread
    server = TCPServer.new("127.0.0.1", 0)
    port = server.addr[1]
    server_pid = fork do
      loop do
        client = server.accept
        request = client.gets
        headers = +""
        while (line = client.gets) && line != "\r\n"
          headers << line
        end
        range = headers.match(/Range: bytes=(\d+)-(\d*)/i)
        first = range ? range[1].to_i : 0
        last = (range && !range[2].empty?) ? range[2].to_i : disk.bytesize - 1
        last = [last, disk.bytesize - 1].min
        body = disk.byteslice(first..last)
        client.write "HTTP/1.1 #{range ? "206 Partial Content" : "200 OK"}\r\n"
        client.write "Content-Length: #{body.bytesize}\r\nAccept-Ranges: bytes\r\nConnection: close\r\n"
        client.write "Content-Range: bytes #{first}-#{last}/#{disk.bytesize}\r\n" if range
        client.write "\r\n"
        client.write body unless request.start_with?("HEAD")
        client.close
      end
    end
    begin
      server.close
      system bin/"qemu-img", "convert", "-f", "raw", "-O", "raw",
             "http://127.0.0.1:#{port}/test.img", "download.img"
      assert_equal disk, (testpath/"download.img").binread
    ensure
      Process.kill("TERM", server_pid)
      Process.wait(server_pid)
    end

    assert_match "chardev", shell_output("#{bin}/qemu-system-i386 -device vhost-user-blk-pci,help")

    system bin/"qemu-keymap", "-l", "us", "-f", "us.keymap"
    assert_match "#    layout  : us", (testpath/"us.keymap").read

    # Boot a guest that writes to the debug console and exits through an ISA device.
    boot = [0xba, 0xe9, 0x00, 0xb0, 0x4f, 0xee, 0xb0, 0x4b, 0xee,
            0xba, 0xf4, 0x00, 0xb0, 0x00, 0xee, 0xf4, 0xeb, 0xfd].pack("C*")
    (testpath/"boot.img").binwrite boot.ljust(510, 0.chr) + [0x55, 0xaa].pack("C*")
    shell_output("#{bin}/qemu-system-i386 -accel tcg -display none -monitor none -serial none " \
                 "-drive file=boot.img,format=raw,if=floppy -boot a -no-reboot -nic user,model=e1000 " \
                 "-debugcon file:debug.log -device isa-debug-exit,iobase=0xf4,iosize=0x04 " \
                 "-sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny", 1)
    assert_equal "OK", (testpath/"debug.log").read

    if OS.linux? && Hardware::CPU.arm?
      (testpath/"hello.S").write <<~ASM
        .global _start
        .text
        _start:
          mov x0, #0
          adr x1, sigmask
          adr x2, oldmask
          mov x3, #8
          mov x8, #135
          svc #0
          cbnz x0, failure
          mov x0, #2
          adr x1, oldmask
          mov x2, #0
          mov x3, #8
          mov x8, #135
          svc #0
          cbnz x0, failure
          mov x0, #1
          adr x1, message
          mov x2, #2
          mov x8, #64
          svc #0
          mov x0, #0
          mov x8, #93
          svc #0
        failure:
          mov x0, #1
          mov x8, #93
          svc #0
        message:
          .ascii "OK"
        .data
        .balign 8
        sigmask:
          .quad 0xa00
        oldmask:
          .quad 0
      ASM
      system ENV.cc, "-nostdlib", "-static", "hello.S", "-o", "hello"
      assert_equal "OK", shell_output("#{bin}/qemu-aarch64 hello")
    end

    # On macOS, verify that we haven't clobbered the signature on the qemu-system-x86_64 binary
    if OS.mac?
      output = shell_output("codesign --verify --verbose #{bin}/qemu-system-x86_64 2>&1")
      assert_match "valid on disk", output
      assert_match "satisfies its Designated Requirement", output
    end
  end
end
