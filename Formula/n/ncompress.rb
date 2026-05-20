class Ncompress < Formula
  desc "Fast, simple LZW file compressor"
  homepage "https://vapier.github.io/ncompress/"
  url "https://github.com/vapier/ncompress/archive/refs/tags/v5.0.tar.gz"
  sha256 "96ec931d06ab827fccad377839bfb91955274568392ddecf809e443443aead46"
  license "Unlicense"
  head "https://github.com/vapier/ncompress.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5031fc454bb44acd5c80a1363db24bafdd62b7b6dca6f12f8b7221182482e5b5"
  end

  keg_only :provided_by_macos

  def install
    # Remove archaic leading colon before shebang, so that brew install
    # cleanup code correctly preserves executable bit
    inreplace %w[zcmp zdiff zmore], /^:\s*\n#!/, "#!"

    system "make", "install", "BINDIR=#{bin}", "MANDIR=#{man1}"
  end

  test do
    (testpath/"hello").write "Hello, world!"
    system bin/"compress", "-f", "hello"
    assert_match "Hello, world!", shell_output("#{bin}/compress -cd hello.Z")
  end
end
