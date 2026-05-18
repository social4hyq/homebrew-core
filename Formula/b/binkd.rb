class Binkd < Formula
  desc "TCP/IP FTN Mailer"
  homepage "https://github.com/pgul/binkd"
  url "https://github.com/pgul/binkd/archive/refs/tags/binkd-1_0_4.tar.gz"
  sha256 "67cc5c254198005e6d7c5c98b1d161ad146615874df4839daa86735aa5e3fa1d"
  license "GPL-2.0-or-later"
  head "https://github.com/pgul/binkd.git", branch: "master"

  livecheck do
    url :stable
    regex(/^(?:binkd[._-])?v?(\d+(?:[._]\d+)+)$/i)
    strategy :git do |tags|
      tags.filter_map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8d6ed4fb4a7f1655de41efbec583d8d7aa03d585f808a45ecf76ed4507dbd373"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    cp Dir["mkfls/unix/*"].select { |f| File.file? f }, "."
    inreplace "binkd.conf", "/var/", "#{var}/" if build.stable?
    system "./configure", "--disable-silent-rules",
                          "--mandir=#{man}",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system sbin/"binkd", "-v"
  end
end
