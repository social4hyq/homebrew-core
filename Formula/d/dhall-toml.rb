class DhallToml < Formula
  desc "Convert between Dhall and Toml"
  homepage "https://github.com/dhall-lang/dhall-haskell/tree/main/dhall-toml"
  url "https://hackage.haskell.org/package/dhall-toml-1.0.4/dhall-toml-1.0.4.tar.gz"
  sha256 "e2a71fe3a9939728b4829f32146ca949b3c5b3f61e1245486a9fd43ba86f32dc"
  license "BSD-3-Clause"
  head "https://github.com/dhall-lang/dhall-haskell.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6f22b223107ce3e7720d478f89eb60af066c2245f7ff86f32c1116007e66142b"
  end

  depends_on "cabal-install" => :build
  depends_on "ghc" => :build
  depends_on "gmp"

  uses_from_macos "libffi"
  uses_from_macos "ncurses"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Workaround to build aeson with GHC 9.14, https://github.com/haskell/aeson/issues/1155
    args = ["--allow-newer=base,containers,template-haskell"]

    system "cabal", "v2-update"
    system "cabal", "v2-install", *args, *std_cabal_v2_args
  end

  test do
    assert_match "value = 1\n\n", pipe_output("#{bin}/dhall-to-toml", "{ value = 1 }", 0)
    assert_match "\n", pipe_output("#{bin}/dhall-to-toml", "{ value = None Natural }", 0)
  end
end
