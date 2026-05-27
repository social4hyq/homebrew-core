class Htmlcxx < Formula
  desc "Non-validating CSS1 and HTML parser for C++"
  homepage "https://htmlcxx.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/htmlcxx/v0.87/htmlcxx-0.87.tar.gz"
  sha256 "5d38f938cf4df9a298a5346af27195fffabfef9f460fc2a02233cbcfa8fc75c8"
  license all_of: ["LGPL-2.0-only", "Apache-2.0"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6a080e155f69b76640f16e2b5558bda71415a332e84de33d84712b4a65584366"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    ENV.cxx11

    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/htmlcxx -V 2>&1").chomp
  end
end
