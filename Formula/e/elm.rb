class Elm < Formula
  desc "Functional programming language for building browser-based GUIs"
  homepage "https://elm-lang.org"
  url "https://github.com/elm/compiler/archive/refs/tags/0.19.1.tar.gz"
  sha256 "aa161caca775cef1bbb04bcdeb4471d3aabcf87b6d9d9d5b0d62d3052e8250b1"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7168106308bcfe871d8d277d3c777a026b855e4ef1b757d6c0dc450a75bcc782"
  end

  depends_on "cabal-install" => :build
  depends_on "ghc" => :build
  depends_on "gmp"

  uses_from_macos "libffi"
  uses_from_macos "ncurses"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  patch do
    # elm's tarball is not a proper cabal tarball, it contains multiple cabal files.
    # Add `cabal.project` lets cabal-install treat this tarball as cabal project correctly.
    # https://github.com/elm/compiler/pull/2159
    url "https://github.com/elm/compiler/commit/eb566e901a419a6620e43c18faf89f57f0827124.patch?full_index=1"
    sha256 "556ff15fb4d8e5ca6e853280e35389c8875fa31a543204b315b55ec2ac967624"
  end

  patch do
    # These patches allow elm to build on ghc 9.4+.
    url "https://github.com/elm/compiler/commit/0421dfbe48e53d880a401e201890eac0b3de5f06.patch?full_index=1"
    sha256 "b498e39112ab7306b18b47821e799bf436d0c2151836187388c2a6b6f32bd437"
  end

  def install
    # Workaround to build with GHC 9.14. Related issues:
    # https://github.com/well-typed/cborg/issues/373
    # https://github.com/haskellari/these/issues/211
    args = %w[
      --allow-newer=cborg:base,cborg:containers,serialise:base,serialise:containers
      --allow-newer=these:base
      --allow-newer=snap-server:containers
      --constraint=tls>=2
    ]

    system "cabal", "v2-update"
    system "cabal", "v2-install", *args, *std_cabal_v2_args
  end

  test do
    # create elm.json
    elm_json_path = testpath/"elm.json"
    elm_json_path.write <<~JSON
      {
        "type": "application",
        "source-directories": [
                  "."
        ],
        "elm-version": "0.19.1",
        "dependencies": {
                "direct": {
                    "elm/browser": "1.0.0",
                    "elm/core": "1.0.0",
                    "elm/html": "1.0.0"
                },
                "indirect": {
                    "elm/json": "1.0.0",
                    "elm/time": "1.0.0",
                    "elm/url": "1.0.0",
                    "elm/virtual-dom": "1.0.0"
                }
        },
        "test-dependencies": {
          "direct": {},
            "indirect": {}
        }
      }
    JSON

    src_path = testpath/"Hello.elm"
    src_path.write <<~ELM
      module Hello exposing (main)
      import Html exposing (text)
      main = text "Hello, world!"
    ELM

    out_path = testpath/"index.html"
    system bin/"elm", "make", src_path, "--output=#{out_path}"
    assert_path_exists out_path
  end
end
