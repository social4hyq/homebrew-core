class Knock < Formula
  desc "Port-knock server"
  homepage "https://github.com/jvinet/knock"
  url "https://github.com/jvinet/knock/releases/download/v0.8/knock-0.8.tar.gz"
  sha256 "698d8c965624ea2ecb1e3df4524ed05afe387f6d20ded1e8a231209ad48169c7"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "758315e607a4631a432ee00b7049549d3c4eaf6367a4600eac506f23b81d2f6b"
  end

  head do
    url "https://github.com/jvinet/knock.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
  end

  uses_from_macos "libpcap"

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    system bin/"knock", "localhost", "123:tcp"
  end
end
