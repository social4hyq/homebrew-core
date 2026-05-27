class Dcfldd < Formula
  desc "Enhanced version of dd for forensics and security"
  homepage "https://github.com/resurrecting-open-source-projects/dcfldd"
  url "https://github.com/resurrecting-open-source-projects/dcfldd/archive/refs/tags/v1.9.3.tar.gz"
  sha256 "e5813e97bbc8f498f034f5e05178489c1be86de015e8da838de59f90f68491e7"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2d7beed2a6cd4206bb26c74c51b321cf3afd10486788db6999a2ee36f34933bc"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "pkgconf" => :build

  def install
    system "./autogen.sh"
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"dcfldd", "--version"
  end
end
