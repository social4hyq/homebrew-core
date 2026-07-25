class Shmcat < Formula
  desc "Tool that dumps shared memory segments (System V and POSIX)"
  homepage "https://shmcat.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/shmcat/shmcat-1.10.tar.xz"
  sha256 "821212924bf9ef3fbd7a357b4f1065898c12635b86fa5d7bad259533d251076e"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(%r{url=.*?/shmcat[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cd9405482822916c083125bbb2db569b10e39805cdc7d994be3444fba847bcdb"
  end

  def install
    system "./configure", "--prefix=#{prefix}",
                          "--disable-dependency-tracking",
                          "--disable-ftok",
                          "--disable-nls"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/shmcat --version")
  end
end
