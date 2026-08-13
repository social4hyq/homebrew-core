class ZigAT015 < Formula
  desc "General-purpose programming language and toolchain (0.15.x)"
  homepage "https://ziglang.org/"
  # Official prebuilt aarch64-linux static binary (no PT_INTERP, zero NEEDED).
  # Building from source would need llvm@20 — not worth a second LLVM major version.
  url "https://ziglang.org/download/0.15.2/zig-aarch64-linux-0.15.2.tar.xz"
  sha256 "958ed7d1e00d0ea76590d27666efbf7a932281b3d7ba0c6b01b0ff26498f667f"
  license "MIT"
  revision 2

  # Version-pinned: herdr targets a specific minimum_zig_version.
  livecheck do
    url "https://ziglang.org/download/index.json"
    regex(/"tarball":\s*".*?zig-aarch64-linux-(0\.15\.\d+)\.tar\.xz"/i)
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/zig@0.15-v0.15.2-r3"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e5f06ddebeb7970abe4d02308cbe9d4e0bd1b8c43837e6fd130a298959111675"
  end

  depends_on "ohos-bst-light" => :build # self-sign

  def install
    # Guard against binary-sign-tool double-sign (corrupts static ELF).
    # See qemu-aarch64.rb; build.sh UNSET_SIGN_FORMULAS covers CI.
    if ENV["HOMEBREW_OHOS_BOTTLE_BINARY_SIGN"]
      odie "zig@0.15 must be built with HOMEBREW_OHOS_BOTTLE_BINARY_SIGN unset " \
           "(env -u HOMEBREW_OHOS_BOTTLE_BINARY_SIGN brew install ...): the " \
           "binary-sign-tool pass double-signs and corrupts this prebuilt binary"
    end

    # Homebrew strips the top-level dir; buildpath already has zig/lib/doc directly.
    src = buildpath
    odie "zig binary not found at #{src}/zig" unless (src/"zig").exist?

    # self-sign preserves ELF structure (see ohos-bst-light.rb).
    system formula_opt_bin("ohos-bst-light")/"self-sign", (src/"zig").to_s

    # zig resolves lib/ via self-exe-realpath (no env override in 0.15.x).
    # Install the whole tree together, keeping lib/ as zig's sibling.
    libexec.install src.children

    (bin/"zig").write_env_script(
      opt_libexec/"zig",
      "ZIG_GLOBAL_CACHE_DIR" => "${ZIG_GLOBAL_CACHE_DIR:-/data/storage/el2/base/cache/zig}",
    )
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
    # std.debug.print writes to stderr, not stdout.
    assert_match "hello from zig on ohos", shell_output("./hello 2>&1")

    # Cross-compile to musl: herdr's build.rs maps aarch64-unknown-linux-ohos to this triple.
    system bin/"zig", "build-obj", "hello.zig", "-target", "aarch64-linux-musl",
           "-O", "ReleaseFast", "-femit-bin=hello_musl.o"
    assert_path_exists testpath/"hello_musl.o"
  end
end
