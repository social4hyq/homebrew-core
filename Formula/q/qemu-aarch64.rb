class QemuAarch64 < Formula
  desc "QEMU user-mode aarch64 emulator — strace substitute for HarmonyOS"
  homepage "https://qemu.org/"
  # Alpine's prebuilt qemu-aarch64 (user-mode emulator only, no system VM).
  # Fully static musl binary: readelf shows zero NEEDED entries and no
  # interpreter, so it runs as-is on OHOS. Official Alpine CDN (same source
  # family as the libstdc++/libgcc resources in the shim formulae).
  url "https://dl-cdn.alpinelinux.org/alpine/v3.24/community/aarch64/qemu-aarch64-11.0.1-r0.apk"
  version "11.0.1-r0"
  sha256 "c7f5a9821064c23f48916ea68dac44565fa961d49ff360fd12e1ea2fd9727a34"
  license all_of: ["GPL-2.0-only", "LGPL-2.1-only"]
  # Why this exists: on HarmonyOS 6.1, self-signed binaries cannot hold the
  # ptrace permission, so a self-built strace cannot work. QEMU's user-mode
  # -strace is implemented purely in userspace (syscalls are intercepted and
  # forwarded, not virtualized — no ptrace needed), making it the available
  # syscall-tracing substitute. See:
  # https://blog.csdn.net/hqzing/article/details/163311519

  livecheck do
    url "https://pkgs.alpinelinux.org/package/v3.24/community/aarch64/qemu-aarch64"
    regex(%r{<strong>(\d+(?:\.\d+)+-r\d+)</strong>}i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/qemu-aarch64-v11.0.1-r0-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ca7cf28f055e5542faecb7584aa546f4a6fb1903b6f756c949602fb27ec80f7f"
  end

  depends_on "ohos-bst-light" => :build # self-sign

  def install
    # Guard against the binary-sign-tool auto-sign pass: it double-signs and
    # corrupts prebuilt binaries (see the SIGNING notes in zig@0.15.rb;
    # build.sh's UNSET_SIGN_FORMULAS covers CI).
    if ENV["HOMEBREW_OHOS_BOTTLE_BINARY_SIGN"]
      odie "qemu-aarch64 must be built with HOMEBREW_OHOS_BOTTLE_BINARY_SIGN unset " \
           "(env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN brew install ...): the " \
           "binary-sign-tool pass double-signs and corrupts this prebuilt binary"
    end

    # .apk is a gzip tar; brew may or may not have extracted it already.
    src = buildpath/"usr/bin/qemu-aarch64"
    unless src.exist?
      apk = buildpath.glob("*.apk").first
      odie "qemu-aarch64 apk not found" unless apk

      system "tar", "-xzf", apk.to_s, "-C", buildpath.to_s
    end
    odie "qemu-aarch64 binary not found in apk" unless src.exist?

    # OHOS refuses to exec unsigned ELFs. self-sign (not binary-sign-tool):
    # it preserves the ELF structure (see ohos-bst-light.rb).
    system formula_opt_bin("ohos-bst-light")/"self-sign", src.to_s

    bin.install src
    chmod 0755, bin/"qemu-aarch64"
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
