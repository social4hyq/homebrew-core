class BunBootstrap < Formula
  desc "Prebuilt Bun for bootstrapping Bun builds (L3 driver)"
  homepage "https://github.com/oven-sh/bun"
  license "MIT"

  # 预编译 tarball,作为本仓库的 release asset 托管(不进 git)。
  # 自举链:用这个 bun 执行 `bun bd` 来编译目标 bun。
  # 等同 rust 的 bootstrap compiler / ghc 的 ghc-bootstrap。
  url "https://github.com/social4hyq/homebrew-core/releases/download/bun-bootstrap-v1.4.0-a4cd4d2/bun-ohos-aarch64-1.4.0-a4cd4d2.tar.gz"
  version "1.4.0-a4cd4d2"
  sha256 "80d88257496b634b55b61e3b1dd82b902b8f6669b74547931c582ed67437f008"

  bottle do
    root_url "https://github.com/social4hyq/homebrew-core/releases/download/bun-bootstrap-v1.4.0-a4cd4d2"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9ed14895bd4ac371829b7b91be2b9704a30c2bd1aa00ed5fe80e8eec73edb3c0"
  end

  # 预编译二进制,无源码构建步骤;仅构建期被 bun/bun-canary 引用,不进入运行时。
  keg_only "bootstrap only; not for direct use"

  depends_on "ohos-sdk"

  def install
    # tarball 内是 bun 二进制(LLD 已嵌 --code-sign 段,无 binary-sign-tool 签名)。
    # OHOS 要求 ELF 同时具备 LLD code-sign + binary-sign-tool 证书才能执行。
    libexec.install Dir["*"]

    sign_tool = Formula["ohos-sdk"].opt_bin/"binary-sign-tool"
    if sign_tool.exist? && (libexec/"bun").exist?
      ohai "Stripping existing .codesign section (from LLD)"
      system "llvm-objcopy", "--remove-section=.codesign", libexec/"bun"
      ohai "Self-signing bootstrap bun"
      system sign_tool, "sign", "-selfSign", "1",
             "-inFile", libexec/"bun", "-outFile", libexec/"bun.signed"
      (libexec/"bun.signed").chmod(0755)
      bin.install_symlink libexec/"bun.signed" => "bun"
    else
      bin.install_symlink libexec/"bun" => "bun"
    end
  end

  def caveats
    <<~EOS
      bun-bootstrap provides a prebuilt Bun (L3 driver) used to run `bun bd`
      when building Bun from source. It is keg-only and not intended for
      direct use — install `bun` instead.
    EOS
  end

  test do
    # bootstrap bun 能执行并输出版本(验证签名后的二进制可运行)
    assert_match "bun", shell_output("#{bin}/bun --version").downcase
  end
end
