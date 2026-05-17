class Imageworsener < Formula
  desc "Utility and library for image scaling and processing"
  homepage "https://entropymine.com/imageworsener/"
  url "https://entropymine.com/imageworsener/imageworsener-1.3.5.tar.gz"
  sha256 "a7fbb65c5ade67d9ebc32e52c58988a4f986bacc008c9021fe36b598466d5c8d"
  license "MIT"

  livecheck do
    url :homepage
    regex(/href=.*?imageworsener[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "db2a0ba15a90e4d51755fabc8acaa20895ff5e601dc0b77d1108b4594806e9a8"
  end

  head do
    url "https://github.com/jsummers/imageworsener.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "jpeg-turbo"
  depends_on "libpng"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    if build.head?
      inreplace "./scripts/autogen.sh", "libtoolize", "glibtoolize"
      system "./scripts/autogen.sh"
    end

    system "./configure", *std_configure_args, "--without-webp"
    system "make", "install"
    pkgshare.install "tests"
  end

  test do
    cp_r Dir["#{pkgshare}/tests/*"], testpath
    system "./runtest", bin/"imagew"
  end
end
