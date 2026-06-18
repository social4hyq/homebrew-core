class Posh < Formula
  desc "Policy-compliant ordinary shell"
  homepage "https://salsa.debian.org/clint/posh"
  url "https://salsa.debian.org/clint/posh/-/archive/debian/0.14.5/posh-debian-0.14.5.tar.bz2"
  sha256 "dcb22cf8761f1d7c805f9af08dd1e91a91079850fd0b56df88c2240fa3e5f8ac"
  license "GPL-3.0-or-later"

  livecheck do
    url :stable
    regex(%r{^debian/v?(\d+(?:\.\d+)+)$}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b6fe109b9c3e821a130a128e1187090c8a2766db631bad08a080103c210ff101"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  def install
    # Upstream still uses K&R function definitions, which do not compile as C23.
    ENV["ac_cv_prog_cc_c23"] = "no"
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/posh -c 'echo homebrew'")
    assert_equal "homebrew", output.chomp
  end
end
