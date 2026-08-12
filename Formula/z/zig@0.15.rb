class ZigAT015 < Formula
  desc "General-purpose programming language and toolchain (0.15.x)"
  homepage "https://ziglang.org/"
  # Official prebuilt aarch64-linux release tarball, fetched directly rather
  # than built from source. Upstream homebrew-core builds zig@0.15 from
  # source (depends_on "llvm@20"/"lld@20"/"cmake"), but this tap only has
  # llvm@21 (a single ~62min build on its own) — bootstrapping a second LLVM
  # major version just to compile zig is not worth it when ziglang.org
  # already ships a static musl aarch64-linux build. Verified 2026-08-07:
  # readelf -h shows a plain AArch64 EXEC, and `readelf -l | grep -i interp`
  # finds no PT_INTERP segment — it's fully static, same shape as
  # qemu-aarch64.
  url "https://ziglang.org/download/0.15.2/zig-aarch64-linux-0.15.2.tar.xz"
  sha256 "958ed7d1e00d0ea76590d27666efbf7a932281b3d7ba0c6b01b0ff26498f667f"
  license "MIT"

  # Version-pinned like llvm@21/icu4c@78: herdr (and anything else on this
  # tap needing zig) targets a specific minimum_zig_version, so this must
  # stay a manually-bumped, explicitly-versioned formula rather than
  # tracking zig's moving `latest`.
  livecheck do
    url "https://ziglang.org/download/index.json"
    regex(/"tarball":\s*".*?zig-aarch64-linux-(0\.15\.\d+)\.tar\.xz"/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zig@0.15-v0.15.2-r1"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "36643e78697dc28ed2638610419ae42aa6bf40be264307da39d25d2ce3701112"
  end

  # No `bottle do` block yet — CI's pr-validate.yml builds from source,
  # bottles, and pushes it back onto the PR branch (same flow sshport.rb's
  # initial "new formula" commit went through; c51fb9f/a7848a9 in tap
  # history). Verified locally in the OHOS container 2026-08-07 anyway:
  # `brew bottle --json` produced arm64_ohos sha256
  # c85115c07523c461869b4e7fd10b828911f4ecbcb8bf039654fa687122464d56 — kept
  # here as a paper trail, not wired in (that artifact was never uploaded).
  depends_on "ohos-bst-light" => :build # self-sign

  def install
    # Guard against the binary-sign-tool auto-sign pass: it double-signs and
    # corrupts prebuilt static ELF binaries (see the SIGNING notes in
    # qemu-aarch64.rb; build.sh's UNSET_SIGN_FORMULAS covers CI). Confirmed
    # 2026-08-07: the raw downloaded `zig` binary already ran
    # clean after a single self-sign pass on real hardware.
    if ENV["HOMEBREW_OHOS_BOTTLE_BINARY_SIGN"]
      odie "zig@0.15 must be built with HOMEBREW_OHOS_BOTTLE_BINARY_SIGN unset " \
           "(env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN brew install ...): the " \
           "binary-sign-tool pass double-signs and corrupts this prebuilt binary"
    end

    # Homebrew's tar unpack strips the tarball's single top-level directory
    # (zig-aarch64-linux-#{version}/), so buildpath itself already contains
    # zig/lib/doc directly — verified 2026-08-07, this is not the plain
    # `tar xJf` layout you'd get extracting the tarball by hand.
    src = buildpath
    odie "zig binary not found at #{src}/zig" unless (src/"zig").exist?

    # self-sign (not binary-sign-tool): preserves the ELF structure of a
    # static binary — see ohos-bst-light.rb / qemu-aarch64.rb.
    system formula_opt_bin("ohos-bst-light")/"self-sign", (src/"zig").to_s

    # zig finds its own lib/ directory by resolving the *real* path of its
    # own executable (self-exe-relative lookup) — there's no env var
    # override for this in 0.15.x. So the whole extracted tree (zig binary
    # + lib/ + doc/) has to be installed together and stay in that same
    # relative shape; it can't be flattened into bin/. Verified 2026-08-07:
    # running the self-signed binary straight out of the extracted
    # directory (so lib/ was a sibling) built and ran a real ReleaseFast
    # executable, and separately cross-compiled a -target aarch64-linux-musl
    # object file cleanly (this is the target libghostty-vt's build.zig
    # will need mapped from aarch64-unknown-linux-ohos, per herdr.rb).
    libexec.install src.children

    # bin/zig execs the real libexec binary directly (opt_libexec, prefix-
    # relative and stable — same self-reference pattern as zellij.rb),
    # keeping lib/ as its sibling so self-exe-relative lookup still
    # resolves.
    (bin/"zig").write <<~SH
      #!/bin/sh
      export TMPDIR="${TMPDIR:-/data/storage/el2/base/tmp}"
      export ZIG_GLOBAL_CACHE_DIR="${ZIG_GLOBAL_CACHE_DIR:-/data/storage/el2/base/cache/zig}"
      exec "#{opt_libexec}/zig" "$@"
    SH
    chmod 0755, bin/"zig"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/zig version")

    (testpath/"hello.zig").write <<~ZIG
      const std = @import("std");
      pub fn main() void {
          std.debug.print("hello from zig on ohos\\n", .{});
      }
    ZIG
    system bin/"zig", "build-exe", "hello.zig", "-O", "ReleaseFast"
    # std.debug.print writes to stderr, not stdout — redirect it in.
    assert_match "hello from zig on ohos", shell_output("./hello 2>&1")

    # Cross-compiling to aarch64-linux-musl is the load-bearing capability
    # for downstream OHOS consumers (herdr's build.rs maps
    # aarch64-unknown-linux-ohos to this triple for libghostty-vt).
    system bin/"zig", "build-obj", "hello.zig", "-target", "aarch64-linux-musl",
           "-O", "ReleaseFast", "-femit-bin=hello_musl.o"
    assert_path_exists testpath/"hello_musl.o"
  end
end
