class ElmFormat < Formula
  desc "Elm source code formatter, inspired by gofmt"
  homepage "https://github.com/avh4/elm-format"
  url "https://github.com/avh4/elm-format.git",
      tag:      "0.8.8",
      revision: "d07fddc8c0eef412dba07be4ab8768d6abcca796"
  license "BSD-3-Clause"
  head "https://github.com/avh4/elm-format.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "51dd91e5480004afb28c310d8e292eeea9ffdcd6f2efa67c1cac5013ad5aa5bd"
  end

  depends_on "cabal-install" => :build
  depends_on "ghc" => :build
  depends_on "hpack" => :build
  depends_on "gmp"

  uses_from_macos "libffi"

  def install
    # Remove requirement on specific patch GHC
    (buildpath/"cabal.project.freeze").truncate(0)
    inreplace "cabal.project", /^with-compiler: .*$/, ""

    # Workaround to build aeson with GHC 9.14, https://github.com/haskell/aeson/issues/1155
    (buildpath/"cabal.project.local").write "allow-newer: base, containers, template-haskell\n"

    system "cabal", "v2-update"

    # Directly running `cabal v2-install` fails: Invalid file name in tar archive: "avh4-lib-0.0.0.1/../"
    # Instead, we can use the upstream's build.sh script, which utilizes the Shake build system.
    system "./dev/build.sh", "--", "_build/bin/elm-format/O2/elm-format"
    bin.install "_build/bin/elm-format/O2/elm-format"
  end

  test do
    src_path = testpath/"Hello.elm"
    src_path.write <<~ELM
      import Html exposing (text)
      main = text "Hello, world!"
    ELM

    system bin/"elm-format", "--elm-version=0.18", testpath/"Hello.elm", "--yes"
    system bin/"elm-format", "--elm-version=0.19", testpath/"Hello.elm", "--yes"

    assert_match version.to_s, shell_output("#{bin}/elm-format --help")
  end
end
