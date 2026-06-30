class Attr < Formula
  desc "Manipulate filesystem extended attributes"
  homepage "https://savannah.nongnu.org/projects/attr"
  url "https://download.savannah.nongnu.org/releases/attr/attr-2.6.0.tar.gz"
  mirror "https://mirror.csclub.uwaterloo.ca/nongnu/attr/attr-2.6.0.tar.gz"
  sha256 "d42fa374513180bb48cb11a46696f488240e5124ff1e6ad88b0abff706985612"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://download.savannah.nongnu.org/releases/attr/"
    regex(/href=.*?attr[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c5a8f2e5b50a77b37b68fb5ec451d9d6ba52ad1f9a6d3d784f6b38a39de00e62"
  end

  depends_on :linux

  def install
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.txt").write("Hello World!\n")
    output = pipe_output("#{bin}/attr -s name test.txt", "", 0)
    assert_match 'Attribute "name" set to a 0 byte value for test.txt', output
    output = shell_output("#{bin}/attr -l test.txt")
    assert_match 'Attribute "name" has a 0 byte value for test.txt', output
  end
end
