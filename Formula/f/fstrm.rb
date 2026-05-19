class Fstrm < Formula
  desc "Frame Streams implementation in C"
  homepage "https://github.com/farsightsec/fstrm"
  license "MIT"

  stable do
    url "https://dl.farsightsecurity.com/dist/fstrm/fstrm-0.6.1.tar.gz"
    sha256 "bca4ac1e982a2d923ccd24cce2c98f4ceeed5009694430f73fc0dcebca8f098f"

    # Fix -flat_namespace being used on Big Sur and later.
    patch do
      url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
      sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
    end
  end

  # GitHub release descriptions contain a link to the `stable` tarball.
  livecheck do
    url :head
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "67fcca3b21e0a648ee86f19af511fcac4681a380afabdbf4fe94a6fa1121e6c2"
  end

  head do
    url "https://github.com/farsightsec/fstrm.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkgconf" => :build
  depends_on "libevent"

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    job = spawn bin/"fstrm_capture", "-t", "protobuf:dnstap.Dnstap",
                                     "-u", "dnstap.sock", "-w", "capture.fstrm", "-dddd"
    sleep 2

    system bin/"fstrm_dump", "capture.fstrm"
  ensure
    Process.kill("TERM", job)
  end
end
