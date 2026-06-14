class HaskellStack < Formula
  desc "Cross-platform program for developing Haskell projects"
  homepage "https://haskellstack.org/"
  url "https://github.com/commercialhaskell/stack/archive/refs/tags/v3.11.1.tar.gz"
  sha256 "388916c20e2a9e9d343ef40c0c31fbb664cdbf302122ded8508ded8f765cbb4f"
  license "BSD-3-Clause"
  head "https://github.com/commercialhaskell/stack.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7d968b1d5228fac472db0977debe1d5f4f09cab55983d6ba0679dac3937663d4"
  end

  depends_on "cabal-install" => :build
  depends_on "ghc" => :build
  depends_on "gmp"

  uses_from_macos "libffi"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # Remove locked dependencies which only work with a single patch version of GHC.
    # If there are issues resolving dependencies, then can consider bootstrapping with stack instead.
    (buildpath/"cabal.project").unlink
    (buildpath/"cabal.project").write <<~EOS
      packages: .
    EOS

    # Workaround to build aeson with GHC 9.14, https://github.com/haskell/aeson/issues/1155
    args = ["--allow-newer=base,containers,template-haskell"]

    system "cabal", "v2-update"
    system "cabal", "v2-install", *args, *std_cabal_v2_args

    [:bash, :fish, :zsh].each do |shell|
      generate_completions_from_executable(bin/"stack", "--#{shell}-completion-script", bin/"stack",
                                           shells: [shell], shell_parameter_format: :none)
    end
  end

  test do
    system bin/"stack", "new", "test"
    assert_path_exists testpath/"test"
    assert_match "# test", (testpath/"test/README.md").read
  end
end
