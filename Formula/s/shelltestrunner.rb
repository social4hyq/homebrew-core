class Shelltestrunner < Formula
  desc "Portable command-line tool for testing command-line programs"
  homepage "https://github.com/simonmichael/shelltestrunner"
  url "https://hackage.haskell.org/package/shelltestrunner-1.11/shelltestrunner-1.11.tar.gz"
  sha256 "b1742f8c0262034197faa879f1871848a3c404bc8a8aab706fbd053130d3414d"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b6a5f96131623493afe000b344fc3e5f0963fcc15d29f738c2cd1f1d31d9ae21"
  end

  depends_on "cabal-install" => :build
  depends_on "ghc" => :build
  depends_on "gmp"

  uses_from_macos "libffi"

  def install
    system "cabal", "v2-update"
    system "cabal", "v2-install", *std_cabal_v2_args
  end

  test do
    (testpath/"test").write "$$$ {exe} {in}\n>>> /{out}/\n>>>= 0"
    args = "-D{exe}=echo -D{in}=message -D{out}=message -D{doNotExist}=null"
    assert_match "Passed", shell_output("#{bin}/shelltest #{args} test")
  end
end
