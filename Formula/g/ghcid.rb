class Ghcid < Formula
  desc "Very low feature GHCi based IDE"
  homepage "https://github.com/ndmitchell/ghcid"
  url "https://github.com/ndmitchell/ghcid/archive/refs/tags/v0.8.9.tar.gz"
  sha256 "8e6ba85ef6184020a6e11fac5226c6a13e905c44b2e56d288f1fd0b3f0b34038"
  license "BSD-3-Clause"
  head "https://github.com/ndmitchell/ghcid.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "00d7a6a8a46346f4dbee1a5efe9695e909325c7ce2734abcee5dbd55bdbcd4eb"
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
      assert_match "Loading ghci Main.hs", output
    ensure
      Process.kill "TERM", pid
      Process.wait pid
    end
  end
end
