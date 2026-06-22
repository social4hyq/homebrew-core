class BunPty < Formula
  desc "bun-pty native shared library for HarmonyOS aarch64"
  homepage "https://github.com/sursaone/bun-pty"
  license "MIT"

  # bun-pty 上游源码。brew install 时 clone 到 buildpath。
  stable do
    url "https://github.com/sursaone/bun-pty.git",
        tag: "v0.4.10",
        revision: "f46192643865ab7fe7a76da63363f5d174210bfe"
  end

  bottle do
    root_url "https://github.com/social4hyq/homebrew-core/releases/download/bun-pty-v0.4.10"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "da10d8b9d51837b604e2fbb7dbfab9261d0009ca9a771058b9e8a4b25e542fa7"
  end

  # portable-pty 上游源码(crates.io 0.9.0)。其默认 nix 0.28 不支持 OHOS,
  # 在 install 里把 nix 升到 0.31(nix 0.30 起支持 *-unknown-linux-ohos,
  # 见 nix-rust/nix#2599/#2587/#2456)。仅此一行 inreplace,无需 fork 仓库。
  resource "portable-pty" do
    url "https://static.crates.io/crates/portable-pty/0.9.0/download"
    sha256 "b4a596a2b3d2752d94f51fac2d4a96737b8705dddd311a32b9af47211f08671e"
  end

  keg_only "consumed in-tree by opencode build"

  depends_on "rust" => :build
  depends_on "ohos-sdk"   # binary-sign-tool:OHOS .so 须签名方可加载

  def install
    # 1. 解压 portable-pty 源码;glob 定位包根(.crate 可能扁平或带版本号顶层目录)。
    pp_dir = buildpath/"portable-pty-src"
    pp_dir.install resource("portable-pty")
    pp_src = (pp_dir/"Cargo.toml").exist? ? pp_dir : pp_dir.glob("portable-pty-*/Cargo.toml").first&.dirname
    odie "portable-pty source not staged under #{pp_dir}" if pp_src.nil?

    # 2. 把 portable-pty 的 nix 依赖从 0.28 升到 0.31(OHOS 支持)
    inreplace pp_src/"Cargo.toml", 'version = "0.28"', 'version = "0.31"'

    # 3. 把 rust-pty/Cargo.toml 的 portable-pty 改指到上面这份源码(path 依赖)
    inreplace "rust-pty/Cargo.toml" do |s|
      s.sub!(/^portable-pty\s*=.*/,
             %(portable-pty = { path = "#{pp_src}", features = ["serde_support"] }))
    end

    # 4. 原生编译(OHOS 主机,rust host == aarch64-unknown-linux-ohos,无需 NDK/sysroot)。
    #    superenv 适配:rustc_wrapper shim 是 #!/bin/bash 而 OHOS 无 /bin/bash → 删除;
    #    OHOS musl 无系统 CA store → 给 cargo 指 CA bundle(同 bun.rb)。
    ENV.delete("RUSTC_WRAPPER")
    ENV["SSL_CERT_FILE"]  = (HOMEBREW_PREFIX/"etc/ca-certificates/cert.pem").to_s
    ENV["CURL_CA_BUNDLE"] = ENV["SSL_CERT_FILE"]

    cd "rust-pty" do
      system "cargo", "build", "--release", "--target", "aarch64-unknown-linux-ohos"
    end

    # 5. 签名 + 安装
    so = buildpath/"rust-pty/target/aarch64-unknown-linux-ohos/release/librust_pty.so"
    odie "librust_pty.so build failed" unless so.exist?
    sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    system sign_tool, "sign", "-selfSign", "1", "-inFile", so.to_s, "-outFile", so.to_s
    chmod 0755, so
    lib.install so => "librust_pty.so"
  end

  test do
    assert_predicate lib/"librust_pty.so", :exist?
  end
end
