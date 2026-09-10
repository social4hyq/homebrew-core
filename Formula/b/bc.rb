class Bc < Formula
  desc "Arbitrary precision numeric processing language"
  homepage "https://www.gnu.org/software/bc/"
  url "https://ftpmirror.gnu.org/gnu/bc/bc-1.08.2.tar.gz"
  mirror "https://ftp.gnu.org/gnu/bc/bc-1.08.2.tar.gz"
  sha256 "ae470fec429775653e042015edc928d07c8c3b2fc59765172a330d3d87785f86"
  license "GPL-3.0-or-later"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f6bfa3f477e5615673071b6d60121de4c00865a0c2d79e1bc530bf32b7191e81"
  end

  keg_only :provided_by_macos # before Ventura

  uses_from_macos "bison" => :build
  uses_from_macos "ed" => :build
  uses_from_macos "flex"
  uses_from_macos "libedit"

  on_system :linux, macos: :ventura_or_newer do
    depends_on "texinfo" => :build
  end

  conflicts_with "bc-gh", because: "both install `bc` and `dc` binaries"

  def install
    # prevent user BC_ENV_ARGS from interfering with or influencing the
    # bootstrap phase of the build, particularly
    # BC_ENV_ARGS="--mathlib=./my_custom_stuff.b"
    ENV.delete("BC_ENV_ARGS")

    system "./configure", "--disable-silent-rules",
                          "--infodir=#{info}",
                          "--mandir=#{man}",
                          "--with-libedit",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"bc", "--version"
    assert_match "2", pipe_output(bin/"bc", "1+1\n", 0)
  end
end
