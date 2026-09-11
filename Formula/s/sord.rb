class Sord < Formula
  desc "C library for storing RDF data in memory"
  homepage "https://drobilla.net/software/sord.html"
  url "https://download.drobilla.net/sord-0.16.22.tar.xz"
  sha256 "bb23b34b216579136795d518cffa73d91cf205594ce9accebfd408afb839173f"
  license "ISC"
  revision 1

  livecheck do
    url "https://download.drobilla.net"
    regex(/href=.*?sord[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ae8dcbe53bc3ab5f16747c0b9bfe4fa83d34dc404410afd62eff4fc0d34f18ad"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "pcre2"
  depends_on "serd"
  depends_on "zix"

  def install
    system "meson", "setup", "build", "-Dtests=disabled", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    path = testpath/"input.ttl"
    path.write <<~EOS
      @prefix : <http://example.org/base#> .
      :a :b :c .
    EOS

    output = "<http://example.org/base#a> <http://example.org/base#b> <http://example.org/base#c> .\n"
    assert_equal output, shell_output("#{bin}/sordi input.ttl")
  end
end
