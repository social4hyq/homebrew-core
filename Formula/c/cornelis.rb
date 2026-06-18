class Cornelis < Formula
  desc "Neovim support for Agda"
  homepage "https://github.com/agda/cornelis"
  url "https://github.com/agda/cornelis/archive/refs/tags/v2.8.0.tar.gz"
  sha256 "41787428319dbde15b51ce427451d4a48f14d54a7c42902d004458e232ca3022"
  license "BSD-3-Clause"
  head "https://github.com/agda/cornelis.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bf28a9224af0e5538ae11565634b342fad8ba0e3dc52c7c73f2251e27d696343"
  end

  depends_on "cabal-install" => :build
  depends_on "ghc" => :build
  depends_on "hpack" => :build
  depends_on "gmp"

  uses_from_macos "libffi"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "hpack"
    system "cabal", "v2-update"
    system "cabal", "v2-install", *std_cabal_v2_args
  end

  test do
    expected = "\x94\x00\x01\xC4\x15nvim_create_namespace\x91\xC4\bcornelis"
    actual = pipe_output("#{bin}/cornelis NAME", nil, 0)
    assert_equal expected, actual
  end
end
