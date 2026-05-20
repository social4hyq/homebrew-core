class Rdfind < Formula
  desc "Find duplicate files based on content (NOT file names)"
  homepage "https://rdfind.pauldreik.se/"
  url "https://rdfind.pauldreik.se/rdfind-1.8.0.tar.gz"
  sha256 "0a2d0d32002cc2dc0134ee7b649bcc811ecfb2f8d9f672aa476a851152e7af35"
  license "GPL-2.0-or-later"
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?rdfind[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ca96dfb9b4abbdb6fa762a00c3257ae9a23298fbb2f223708d7a7f3ea553d5bf"
  end

  depends_on "nettle"

  def install
    ENV.append "CXXFLAGS", "-std=c++17"

    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    mkdir "folder"
    (testpath/"folder/file1").write("foo")
    (testpath/"folder/file2").write("bar")
    (testpath/"folder/file3").write("foo")
    system bin/"rdfind", "-deleteduplicates", "true", "folder"
    assert_path_exists testpath/"folder/file1"
    assert_path_exists testpath/"folder/file2"
    refute_path_exists testpath/"folder/file3"
  end
end
