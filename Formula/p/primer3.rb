class Primer3 < Formula
  desc "Program for designing PCR primers"
  homepage "https://primer3.org/"
  url "https://github.com/primer3-org/primer3/archive/refs/tags/v2.6.1.tar.gz"
  sha256 "805cef7ef39607cd40f0f5bb8b32e35e20007153a0a55131dd430ce644c8fb9e"
  license all_of: [
    "GPL-2.0-or-later",
    "GPL-3.0-or-later", # Amplicon3
  ]

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8a98939c0ee619cce38b67827e717de544948d217514619599d8e07c5c58e29d"
  end

  def install
    system "make", "-C", "src", "install", "PREFIX=#{prefix}"
    pkgshare.install "src/primer3_config"
    prefix.install "src/LICENSE_GPL3_for_Amplicon3"
  end

  test do
    output = shell_output("#{bin}/long_seq_tm_test AAAAGGGCCCCCCCCTTTTTTTTTTT 3 20")
    assert_match "tm = 52.452902", output.lines.last
  end
end
