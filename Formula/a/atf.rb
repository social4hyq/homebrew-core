class Atf < Formula
  desc "Automated testing framework"
  homepage "https://github.com/freebsd/atf"
  url "https://github.com/freebsd/atf/releases/download/atf-0.23/atf-0.23.tar.gz"
  sha256 "a64e2427d021297f25b3f2e1798f8ec4dc3061ffb01a1cd3f66cc4cee486b10f"
  license "BSD-2-Clause"
  head "https://github.com/freebsd/atf.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "de0b68beae3b78786aed4202ca48e48a8bc01e3fc307bf9c994b7e80ab9ed3b4"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    system "glibtoolize", "--force", "--install"
    system "autoreconf", "--force", "--install", "--verbose"

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--sysconfdir=#{etc}"
    system "make"
    ENV.deparallelize
    system "make", "install"
  end

  test do
    (testpath/"test.sh").write <<~SHELL
      #!/usr/bin/env atf-sh
      echo test
      exit 0
    SHELL
    system "bash", "test.sh"
  end
end
