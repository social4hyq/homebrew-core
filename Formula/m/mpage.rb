class Mpage < Formula
  desc "Many to one page printing utility"
  homepage "https://mesa.nl/pub/mpage/README"
  url "https://mesa.nl/pub/mpage/mpage-2.5.8.tgz"
  sha256 "2351e91d25794b358df6618f17a7013a28d350ec20408fe06f8123dc4673fe93"
  license "GPL-2.0-or-later"

  livecheck do
    url "https://mesa.nl/pub/mpage/"
    regex(/href=.*?mpage[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4b1a54d9414e503aa65063f187703cb6f0514e1a159cc25fa9e81136e2269ee3"
  end

  def install
    args = %W[
      MANDIR=#{man1}
      PREFIX=#{prefix}
    ]
    system "make", *args
    system "make", "install", *args
  end

  test do
    (testpath/"input.txt").write("Input text")
    system bin/"mpage", "input.txt"
  end
end
