class TaskSpooler < Formula
  desc "Batch system to run tasks one after another"
  homepage "https://viric.name/soft/ts/"
  url "https://viric.name/soft/ts/ts-1.0.4.tar.gz"
  sha256 "b1ab3db52dca36af3699178b8d0e936a30107f8d5c86a974163c580823b01790"
  license "GPL-2.0-only"

  livecheck do
    url :homepage
    regex(/href=.*?ts[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bc553cd65a72b8488ca9186dde2a5854b756e7ef27074b30d314cd5a778ed68d"
  end

  conflicts_with "moreutils", because: "both install a `ts` executable"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"ts", "-l"
  end
end
