class CdDiscid < Formula
  desc "Read CD and get CDDB discid information"
  homepage "https://linukz.org/cd-discid.shtml"
  license "GPL-2.0-or-later"
  revision 2
  head "https://github.com/taem/cd-discid.git", branch: "master"

  stable do
    url "https://linukz.org/download/cd-discid-1.4.tar.gz"
    mirror "https://deb.debian.org/debian/pool/main/c/cd-discid/cd-discid_1.4.orig.tar.gz"
    sha256 "ffd68cd406309e764be6af4d5cbcc309e132c13f3597c6a4570a1f218edd2c63"

    # macOS fix; see https://github.com/Homebrew/homebrew/issues/46267
    # Already fixed in upstream head; remove when bumping version to >1.4
    patch do
      url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/cd-discid/1.4.patch"
      sha256 "f53b660ae70e91174ab86453888dbc3b9637ba7fcaae4ea790855b7c3d3fe8e6"
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "7836060456fca0222bc1a8f92cb0c7bbde633eaf62a68041d70313a6c2498193"
  end

  # Last commit was 9 years ago, upstream site is gone
  deprecate! date: "2025-10-16", because: :unmaintained

  def install
    system "make", "CC=#{ENV.cc}"
    bin.install "cd-discid"
    man1.install "cd-discid.1"
  end

  test do
    assert_equal "cd-discid #{version}.", shell_output("#{bin}/cd-discid --version 2>&1").chomp
  end
end
