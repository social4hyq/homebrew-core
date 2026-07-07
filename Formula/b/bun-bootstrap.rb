class BunBootstrap < Formula
  desc "Prebuilt Bun for bootstrapping Bun builds (L3 driver)"
  homepage "https://github.com/oven-sh/bun"
  url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun-bootstrap-v1.4.0-5467a689/bun-ohos-aarch64-1.4.0-5467a689.tar.gz"
  version "1.4.0-5467a689"
  sha256 "7c1f187907eba7090c60e14dc1bc474fd62ec5b6273cc44c571cf18d35305a2b"
  license "MIT"

  # Prebuilt tarball, hosted as a release asset of this repo (not committed to git).
  # Bootstrap chain: use this bun to run `bun bd` to compile the target bun.
  # Equivalent to Rust's bootstrap compiler / GHC's ghc-bootstrap.

  livecheck do
    skip "bootstrap tool, manually pinned to self-bootstrap version"
  end

  bottle do
    root_url "https://atomgit.com/social4hyq/homebrew-core/releases/download/bun-bootstrap-v1.4.0-5467a689"
    sha256 cellar: :any_skip_relocation, arm64_ohos: "463b5efa40e04405914ae629e2762e6710defeeaae73bd6cdcc3d3892cb4d82a"
  end

  # Prebuilt binary, no source build step; only referenced by bun/bun-canary at build time, not at runtime.
  keg_only "bootstrap only; not for direct use"

  def install
    # Tarball contains bun already signed by binary-sign-tool (via bun.rb r16 install block).
    # No strip+resign needed here.
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bun" => "bun"
  end

  def caveats
    <<~EOS
      bun-bootstrap provides a prebuilt Bun (L3 driver) used to run `bun bd`
      when building Bun from source. It is keg-only and not intended for
      direct use — install `bun` instead.
    EOS
  end

  test do
    assert_match version.to_s.split("-").first, shell_output("#{bin}/bun --version")
  end
end
