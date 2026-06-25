class Nsd < Formula
  desc "Name server daemon"
  homepage "https://www.nlnetlabs.nl/projects/nsd/"
  url "https://www.nlnetlabs.nl/downloads/nsd/nsd-4.14.3.tar.gz"
  sha256 "9629ad64d9c1b019bbe22296d5148d7ae65f588ce265a6424750740f052bb12b"
  license "BSD-3-Clause"

  # We check the GitHub repo tags instead of
  # https://www.nlnetlabs.nl/downloads/nsd/ since the first-party site has a
  # tendency to lead to an `execution expired` error.
  livecheck do
    url "https://github.com/NLnetLabs/nsd.git"
    regex(/^NSD[._-]v?(\d+(?:[._]\d+)+)[._-]REL$/i)

    strategy :git do |tags, regex|
      tags.map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4ecdf374b0a8243ffea3bee8ca52cb96b3bf602443c14e07014124508ff06990"
  end

  depends_on "pkgconf" => :build
  depends_on "libevent"
  depends_on "openssl@3"

  def install
    ENV.runtime_cpu_detection if Hardware::CPU.intel?

    system "./configure", "--sysconfdir=#{etc}",
                          "--localstatedir=#{var}",
                          "--disable-dnstap",
                          "--with-libevent=#{Formula["libevent"].opt_prefix}",
                          "--with-ssl=#{Formula["openssl@3"].opt_prefix}",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system sbin/"nsd", "-v"
  end
end
