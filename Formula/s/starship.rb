class Starship < Formula
  desc "Cross-shell prompt for astronauts"
  homepage "https://starship.rs/"
  url "https://github.com/starship/starship/archive/refs/tags/v1.26.0.tar.gz"
  sha256 "8c95e8a6c596b29ac192104eae00dd991e8c8fd66083fd2b34d6b223a5803a59"
  license "ISC"
  head "https://github.com/starship/starship.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/starship-v1.26.0-r1"
    sha256 cellar: "/storage/Users/currentUser/.harmonybrew/Cellar", arm64_ohos: "2b5e1e66503e57ec9585768a512033a1f1a42f69cc9984c401e922b9f8fe373d"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  def install
    # OHOS 适配：关闭 default features（battery + notify）。
    # notify → notify-rust → dbus：OHOS 无 dbus 桌面通知服务，且 tap 无 dbus formula。
    # battery：OHOS 电池 API 语义不同，终端 prompt 无需。
    # 去掉两者后，全部依赖均为纯 Rust crate（gix 用 zlib-rs 纯 Rust 后端），无需系统库。
    #
    # 链接修复：rust libc crate 对 OHOS target 将 strerror_r 的 link_name
    # 声明为 __xpg_strerror_r，但链接器（superenv 注入了 glibc 搜索路径）
    # 找不到该符号。写一个 C 空对象文件提供弱别名，通过 RUSTFLAGS 注入，
    # 确保所有链接阶段（含 build script）都能解析。
    shim = buildpath/"strerror_shim.c"
    shim.write <<~C
      #include <stddef.h>
      int __xpg_strerror_r(int errnum, char *buf, size_t buflen) {
          if (buflen == 0) return 0;
          buf[0] = '\\0';
          return 0;
      }
    C
    system ENV.cc, "-c", "-fPIC", "-o", "strerror_shim.o", shim.to_s
    ENV["RUSTFLAGS"] = "-C link-arg=#{buildpath}/strerror_shim.o"
    system "cargo", "install", *std_cargo_args, "--no-default-features"

    generate_completions_from_executable(bin/"starship", "completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/starship --version")
    ENV["STARSHIP_CONFIG"] = ""
    assert_match "❯", shell_output("#{bin}/starship module character")
  end
end
