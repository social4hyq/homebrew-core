class Apachetop < Formula
  desc "Top-like display of Apache log"
  homepage "https://github.com/tessus/apachetop"
  url "https://github.com/tessus/apachetop/releases/download/0.23.2/apachetop-0.23.2.tar.gz"
  sha256 "f94a34180808c3edb24c1779f72363246dd4143a89f579ef2ac168a45b04443f"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9abd26cccfe22cefb7814ca8dba7202f02b3218388ce801a05aed1aeec7bf1be"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "pkgconf" => :build
  depends_on "adns"
  depends_on "ncurses"
  depends_on "pcre2"

  on_linux do
    depends_on "readline"
  end

  def install
    ENV.append "CXX", "-std=gnu++17"

    system "./configure", "--mandir=#{man}",
                          "--with-logfile=#{var}/log/apache2/access_log",
                          "--with-adns=#{Formula["adns"].opt_prefix}",
                          "--with-pcre2=#{Formula["pcre2"].opt_prefix}",
                          *std_configure_args
    system "make", "install"
  end

  test do
    output = shell_output("#{bin}/apachetop -h 2>&1", 1)
    assert_match "ApacheTop v#{version}", output
  end
end
