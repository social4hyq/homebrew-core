class Pwsafe < Formula
  desc "Generate passwords and manage encrypted password databases"
  homepage "https://github.com/nsd20463/pwsafe"
  url "https://src.fedoraproject.org/repo/pkgs/pwsafe/pwsafe-0.2.0.tar.gz/4bb36538a2772ecbf1a542bc7d4746c0/pwsafe-0.2.0.tar.gz"
  sha256 "61e91dc5114fe014a49afabd574eda5ff49b36c81a6d492c03fcb10ba6af47b7"
  license "GPL-2.0-or-later"
  revision 4

  livecheck do
    url "https://src.fedoraproject.org/repo/pkgs/pwsafe/"
    regex(/href=.*?pwsafe[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  no_autobump! because: :incompatible_version_format

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "48e17c1d9ef7d6bcd8ddc9cc7ec92aa88839cdb60d97200390e3fabae7074fde"
  end

  head do
    url "https://github.com/nsd20463/pwsafe.git", branch: "master"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  depends_on "openssl@4"
  depends_on "readline"

  # A password database for testing is provided upstream. How nice!
  resource "test-pwsafe-db" do
    url "https://raw.githubusercontent.com/nsd20463/pwsafe/208de3a94339df36b6e9cd8aeb7e0be0a67fd3d7/test.dat"
    sha256 "7ecff955871e6e58e55e0794d21dfdea44a962ff5925c2cd0683875667fbcc79"
  end

  def install
    args = ["--mandir=#{man}", "--without-x"]
    if build.head?
      system "autoreconf", "--force", "--install", "--verbose"
    elsif OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      # Help old config scripts identify arm64 linux
      args << "--build=aarch64-unknown-linux-gnu"
    end

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    test_db_passphrase = "abc"
    test_account_name = "testing"
    test_account_pass = "sg1rIWHL?WTOV=d#q~DmxiQq%_j-$f__U7EU"

    resource("test-pwsafe-db").stage(testpath)
    output = pipe_output("#{bin}/pwsafe -f test.dat -p #{test_account_name}", test_db_passphrase, 0)
    assert_match(/^#{Regexp.escape(test_account_pass)}$/, output)
  end
end
