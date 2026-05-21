class Crfxx < Formula
  desc "Conditional random fields for segmenting/labeling sequential data"
  homepage "https://taku910.github.io/crfpp/"
  url "https://mirrors.sohu.com/gentoo/distfiles/f2/CRF%2B%2B-0.58.tar.gz"
  mirror "https://drive.google.com/uc?id=0B4y35FiV1wh7QVR6VXJ5dWExSTQ&export=download"
  sha256 "9d1c0a994f25a5025cede5e1d3a687ec98cd4949bfb2aae13f2a873a13259cb2"
  license any_of: ["LGPL-2.1-only", "BSD-3-Clause"]
  head "https://github.com/taku910/crfpp.git", branch: "master"

  # Archive files from upstream are hosted on Google Drive, so we can't identify
  # versions from the tarballs, as the links on the homepage don't include this
  # information. This identifies versions from the "News" sections, which works
  # for now but may encounter issues in the future due to the loose regex.
  livecheck do
    url :homepage
    regex(/CRF\+\+ v?(\d+(?:\.\d+)+)[\s<]/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1bcd1f02839f2981e021096d49a249358e8149785dec6f60361beefe69bce0a0"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-pre-0.4.2.418-big_sur.diff"
    sha256 "83af02f2aa2b746bb7225872cab29a253264be49db0ecebb12f841562d9a2923"
  end

  def install
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?

    system "./configure", *args, *std_configure_args
    system "make", "CXXFLAGS=#{ENV.cflags}", "install"
  end

  test do
    # Using "; true" because crf_test -v and -h exit nonzero under normal operation
    output = shell_output("#{bin}/crf_test --help; true")
    assert_match "CRF++: Yet Another CRF Tool Kit", output
  end
end
