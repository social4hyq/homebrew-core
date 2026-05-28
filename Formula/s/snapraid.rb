class Snapraid < Formula
  desc "Backup program for disk arrays"
  homepage "https://www.snapraid.it/"
  url "https://github.com/amadvance/snapraid/releases/download/v14.5/snapraid-14.5.tar.gz"
  sha256 "ccbbf089134a2963147aeaa535911ad1868a2786daf54786d633837d4130da54"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0efeacb4c95b91063c5c1c9cf87b91b87dfdfa911ff25c8ac3a3c3ca0b9e0a47"
  end

  head do
    url "https://github.com/amadvance/snapraid.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  def install
    system "./autogen.sh" if build.head?
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/snapraid --version")
  end
end
