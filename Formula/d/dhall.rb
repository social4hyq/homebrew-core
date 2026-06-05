class Dhall < Formula
  desc "Interpreter for the Dhall language"
  homepage "https://dhall-lang.org/"
  url "https://hackage.haskell.org/package/dhall-1.42.3/dhall-1.42.3.tar.gz"
  sha256 "cbb5612d9c55b9b3fa07ab73b72e6445875a6f53283f29979f164a9b3b067a00"
  license "BSD-3-Clause"

  livecheck do
    url "https://hackage-content.haskell.org/package/dhall/docs/"
    strategy :header_match
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "886ceab8aa1c76ce879d6cabd1d78f61680eafdad603e518ddc45c8ed998c421"
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
    man1.install "man/dhall.1"
  end

  test do
    assert_match "{=}", pipe_output("#{bin}/dhall format", "{ = }", 0)
    assert_match "8", pipe_output("#{bin}/dhall normalize", "(\\(x : Natural) -> x + 3) 5", 0)
    assert_match "(x : Natural) -> Natural", pipe_output("#{bin}/dhall type", "\\(x: Natural) -> x + 3", 0)
  end
end
