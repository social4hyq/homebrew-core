class Datamash < Formula
  desc "Tool to perform numerical, textual & statistical operations"
  homepage "https://www.gnu.org/software/datamash/"
  url "https://ftpmirror.gnu.org/gnu/datamash/datamash-1.9.tar.gz"
  mirror "https://ftp.gnu.org/gnu/datamash/datamash-1.9.tar.gz"
  sha256 "f382ebda03650dd679161f758f9c0a6cc9293213438d4a77a8eda325aacb87d2"
  license "GPL-3.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a1a76868cf966b83fc397e5b776cd1a0a7a2247b3ea5a7e439494dbbc9b89119"
  end

  head do
    url "https://git.savannah.gnu.org/git/datamash.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "gettext" => :build
  end

  def install
    system "./bootstrap" if build.head?
    system "./configure", *std_configure_args, "--disable-silent-rules"
    system "make", "install"
  end

  test do
    assert_equal "55", pipe_output("#{bin}/datamash sum 1", shell_output("seq 10")).chomp
  end
end
