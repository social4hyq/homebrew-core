class Hadolint < Formula
  desc "Smarter Dockerfile linter to validate best practices"
  homepage "https://github.com/hadolint/hadolint"
  url "https://github.com/hadolint/hadolint/archive/refs/tags/v2.14.0.tar.gz"
  sha256 "002a411ac608696327d65aaa6e77c8fafe2561429ce56cca0ccb67c2956f8dd5"
  license "GPL-3.0-only"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6021fc92e8765be403102bf1c664d5ef0bb5f8346272364b0b5e080dfd7f4b26"
  end

  depends_on "cabal-install" => :build
  depends_on "ghc" => :build
  depends_on "gmp"

  uses_from_macos "libffi"
  uses_from_macos "xz"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Workaround for GHC 9.12 until https://github.com/phadej/puresat/pull/7
    # and base is updated in https://github.com/phadej/spdx
    # Workaround to build aeson with GHC 9.14, https://github.com/haskell/aeson/issues/1155
    args = ["--allow-newer=base,containers,template-haskell"]

    system "cabal", "v2-update"
    system "cabal", "v2-install", *args, *std_cabal_v2_args
  end

  test do
    df = testpath/"Dockerfile"
    df.write <<~DOCKERFILE
      FROM debian
    DOCKERFILE
    assert_match "DL3006", shell_output("#{bin}/hadolint #{df}", 1)
  end
end
