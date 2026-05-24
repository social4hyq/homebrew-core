class Mmsrip < Formula
  desc "Client for the MMS:// protocol"
  homepage "https://web.archive.org/web/20241016171436/https://nbenoit.tuxfamily.org/index.php?page=MMSRIP"
  url "https://web.archive.org/web/20161207201859/https://nbenoit.tuxfamily.org/projects/mmsrip/mmsrip-0.7.0.tar.gz"
  sha256 "5aed3cf17bfe50e2628561b46e12aec3644cfbbb242d738078e8b8fce6c23ed6"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "868d8c234f8aed54074c394e538f475aceb2c057ee43ff1de92d2f4c0184f276"
  end

  # Deprecation reasons:
  # * TuxFamily URLs are no longer available (https://forum.tuxfamily.org/topic/775/is-tuxfamily-slowly-dying/)
  # * Analytics on deprecation date were "0 (30 days), 0 (90 days), 5 (365 days)"
  # * Last release in 2006
  # * The MMS protocol was deprecated in 2003
  deprecate! date: "2025-03-17", because: :unmaintained
  disable! date: "2026-03-17", because: :unmaintained

  def install
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}", "--mandir=#{man}"
    system "make"
    system "make", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mmsrip --version 2>&1")
  end
end
