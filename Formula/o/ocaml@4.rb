# OCaml does not preserve binary compatibility across compiler releases,
# so when updating it you should ensure that all dependent packages are
# also updated by incrementing their revisions.
#
# Applications that really shouldn't break on a compiler update are:
# - coccinelle
class OcamlAT4 < Formula
  desc "General purpose programming language in the ML family"
  homepage "https://ocaml.org/"
  url "https://caml.inria.fr/pub/distrib/ocaml-4.14/ocaml-4.14.4.tar.xz"
  sha256 "531df6280ecf3d3029ed4404858d37c122470a04c9a4104e6b48ee4f762f175c"
  license "LGPL-2.1-only" => { with: "OCaml-LGPL-linking-exception" }

  livecheck do
    url "https://ocaml.org/releases"
    regex(%r{href=.*?/releases/v?(4(?:\.\d+)+)/?["']}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2fc131898a84555f25ccefcf0717803d2dc86e4deface78732698becd17069dc"
  end

  # The ocaml compilers embed prefix information in weird ways that the default
  # brew detection doesn't find, and so needs to be explicitly blocked.
  pour_bottle? only_if: :default_prefix

  keg_only :versioned_formula

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    ENV.deparallelize # Builds are not parallel-safe, esp. with many cores

    # the ./configure in this package is NOT a GNU autoconf script!
    args = %W[
      --prefix=#{prefix}
      --enable-debug-runtime
      --mandir=#{man}
    ]
    system "./configure", *args
    system "make", "world.opt"
    system "make", "prefix=#{prefix}", "install"
  end

  test do
    output = pipe_output("#{bin}/ocaml 2>&1", "let x = 1 ;;")
    assert_match "val x : int = 1", output
  end
end
