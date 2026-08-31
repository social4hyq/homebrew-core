class Ghcid < Formula
  desc "Very low feature GHCi based IDE"
  homepage "https://github.com/ndmitchell/ghcid"
  url "https://github.com/ndmitchell/ghcid/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "6317ed3a0c83c1d1d5b03ca40d7b6906d208850b46dd6a372ea90345946f3b4f"
  license "BSD-3-Clause"
  head "https://github.com/ndmitchell/ghcid.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d3b705c50a5e403d9295db403af041ac896afffa42c5b4cf881cc4d26947e7ed"
  end

  depends_on "cabal-install" => :build
  depends_on "ghc" => [:build, :test]
  depends_on "gmp"

  uses_from_macos "libffi"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cabal", "v2-update"
    system "cabal", "v2-install", *std_cabal_v2_args
  end

  test do
    (testpath/"Main.hs").write <<~HASKELL
      main :: IO ()
      main = putStrLn "Hello, World!"
    HASKELL

    PTY.spawn(bin/"ghcid", "--command=ghci Main.hs", "--clear") do |r, _w, pid|
      output = r.gets
      assert_match "Starting ghci command: ghci Main.hs", output
    ensure
      Process.kill "TERM", pid
      Process.wait pid
    end
  end
end
