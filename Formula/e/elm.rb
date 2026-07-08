class Elm < Formula
  desc "Functional programming language for building browser-based GUIs"
  homepage "https://elm-lang.org"
  url "https://github.com/elm/compiler/archive/refs/tags/0.19.2.tar.gz"
  sha256 "745b1edfea2f8e3b36cf6f77ae3b59fd86e8e397d427971f6d903f9fce6163a5"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ec961be4599ccfa525066a85c5fa8c0a5c1f8eef2a237866afca410fa3cba350"
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
    args = %W[
      --jobs=#{ENV.make_jobs}
    ]

    # Following the process from the Dockerfile for building elm binaries here:
    #  https://github.com/elm/compiler/blob/main/installers/linux/Dockerfile
    # This process does not use `cabal install`
    system "cabal", "update"
    system "cabal", "build", "elm", *args
    bin.install Utils.safe_popen_read("cabal", "list-bin", "elm").chomp
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
        "elm-version": "#{version}",
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
