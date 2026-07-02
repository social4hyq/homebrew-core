class BunBootstrap < Formula
  desc "Prebuilt Bun for bootstrapping Bun builds (L3 driver)"
  homepage "https://github.com/oven-sh/bun"
  url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun-bootstrap-v1.4.0-e0acad318/bun-ohos-aarch64-1.4.0-e0acad318.tar.gz"
  version "1.4.0-e0acad318"
  sha256 "3f750dd48448fecf720b3f61a9517d625451774dee67a22882622d0204b9a7f2"
  license "MIT"

  # Prebuilt tarball, hosted as a release asset of this repo (not committed to git).
  # Bootstrap chain: use this bun to run `bun bd` to compile the target bun.
  # Equivalent to Rust's bootstrap compiler / GHC's ghc-bootstrap.

  livecheck do
    skip "bootstrap tool, manually pinned to self-bootstrap version"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun-bootstrap-v1.4.0-e0acad318"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9a71df0c888aa49f1b56ae1c53368d141443a6b911458d24d45831a79795492c"
  end

  # Prebuilt binary, no source build step; only referenced by bun/bun-canary at build time, not at runtime.
  keg_only "bootstrap only; not for direct use"

  depends_on "ohos-sdk"

  def install
    # tarball contains the bun binary (LLD has already embedded --code-sign section, no binary-sign-tool signature).
    # OHOS requires ELF to have both LLD code-sign and binary-sign-tool certificate to execute.
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
    # bootstrap bun can execute and output version (verify the signed binary is runnable)
    assert_match "bun", shell_output("#{bin}/bun --version").downcase
  end
end
