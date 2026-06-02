class Wwwoffle < Formula
  desc "Better browsing for computers with intermittent connections"
  homepage "https://www.gedanken.org.uk/software/wwwoffle/"
  url "https://www.gedanken.org.uk/software/wwwoffle/download/wwwoffle-2.9j.tgz"
  sha256 "b16dd2549dd47834805343025638c06a0d67f8ea7022101c0ce2b6847ba011c6"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://www.gedanken.org.uk/software/wwwoffle/download/"
    regex(/href=.*?wwwoffle[._-]v?(\d+(?:\.\d+)+[a-z]?)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "339902f2c66c372d7caefe9e044581d25375e90b627ce4539c25cff7d9d22621"
  end

  uses_from_macos "flex" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = []
    # Help old config scripts identify arm64 linux
    args << "--build=aarch64-unknown-linux-gnu" if OS.linux? && Hardware::CPU.arm64?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"wwwoffle", "--version"
  end
end
