class QemuAarch64 < Formula
  desc "QEMU user-mode aarch64 emulator"
  homepage "https://qemu.org/"
  # Alpine prebuilt qemu-aarch64 (user-mode only). Fully static musl: zero NEEDED,
  # no PT_INTERP — runs as-is on OHOS.
  url "https://dl-cdn.alpinelinux.org/alpine/v3.24/community/aarch64/qemu-aarch64-11.0.1-r0.apk"
  version "11.0.1-r0"
  sha256 "c7f5a9821064c23f48916ea68dac44565fa961d49ff360fd12e1ea2fd9727a34"
  license all_of: ["GPL-2.0-only", "LGPL-2.1-only"]
  # OHOS refuses ptrace on self-signed binaries; qemu -strace intercepts syscalls in userspace (no ptrace).

  livecheck do
    url "https://pkgs.alpinelinux.org/package/v3.24/community/aarch64/qemu-aarch64"
    regex(%r{<strong>(\d+(?:\.\d+)+-r\d+)</strong>}i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/qemu-aarch64-v11.0.1-r0-r2"
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0efec74ed85c2cbc49f76c27d38da6d3199343cc9e8e9d4d6c0b49b2a558ee47"
  end

  depends_on "ohos-bst-light" => :build # self-sign

  def install
    # Guard against binary-sign-tool double-sign (corrupts prebuilt binaries).
    if ENV["HOMEBREW_OHOS_BOTTLE_BINARY_SIGN"]
      odie "qemu-aarch64 must be built with HOMEBREW_OHOS_BOTTLE_BINARY_SIGN unset " \
           "(env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN brew install ...): the " \
           "binary-sign-tool pass double-signs and corrupts this prebuilt binary"
    end

    # .apk is gzip tar; may or may not be pre-extracted. Extract if needed,
    # then self-sign (preserves ELF structure).
    src = buildpath/"usr/bin/qemu-aarch64"
    unless src.exist?
      apk = buildpath.glob("*.apk").first
      odie "qemu-aarch64 apk not found" unless apk

      system "tar", "-xzf", apk.to_s, "-C", buildpath.to_s
    end
    odie "qemu-aarch64 binary not found in apk" unless src.exist?

    system formula_opt_bin("ohos-bst-light")/"self-sign", src.to_s

    bin.install src
  end

  def caveats
    <<~EOS
      qemu-aarch64 is a user-mode emulator, NOT a virtual machine: guest
      syscalls are intercepted and forwarded to the HarmonyOS kernel. Trace
      syscalls strace-style with:
        qemu-aarch64 -strace /bin/ls
    EOS
  end

  test do
    assert_match version.to_s.split("-").first,
                 shell_output("#{bin}/qemu-aarch64 --version")
    # Executing a trivial binary under the emulator must succeed.
    system bin/"qemu-aarch64", "/bin/true"
    # -strace must produce strace-format syscall log lines (qemu performs the
    # exec itself, so the log starts at the guest's first syscall).
    assert_match(/^\d+ set_tid_address\(/, shell_output("#{bin}/qemu-aarch64 -strace /bin/true 2>&1"))
  end
end
