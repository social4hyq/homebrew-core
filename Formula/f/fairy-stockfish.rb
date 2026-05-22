class FairyStockfish < Formula
  desc "Strong open source chess variant engine (with largeboards support)"
  homepage "https://fairy-stockfish.github.io/"
  url "https://github.com/fairy-stockfish/Fairy-Stockfish/archive/refs/tags/fairy_sf_14_0_1_xq.tar.gz"
  version "14.0.1"
  sha256 "53914fc89d89afca7cfcfd20660ccdda125f1751f59a68b1f3ed1d4eb6cfe805"
  license "GPL-3.0-or-later"
  head "https://github.com/fairy-stockfish/Fairy-Stockfish.git", branch: "master"

  livecheck do
    url :stable
    regex(/^fairy_sf[._-]v?(\d+(?:[._-]\d+)*)(?:_xq)?$/i)
    strategy :git do |tags, regex|
      tags.filter_map { |tag| tag.match(regex)&.[](1)&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "19b667a2a6fe430934351b3ee2a4bc4fce512b957420065114a448e49d4a7824"
  end

  def install
    arch = if Hardware::CPU.arm?
      if OS.mac?
        "apple-silicon"
      else
        "armv8"
      end
    elsif build.bottle?
      if OS.mac? && MacOS.version.requires_sse41?
        "x86-64-sse41-popcnt"
      else
        "x86-64-ssse3"
      end
    elsif Hardware::CPU.avx2?
      "x86-64-avx2"
    elsif Hardware::CPU.sse4_1?
      "x86-64-sse41-popcnt"
    elsif Hardware::CPU.ssse3?
      "x86-64-ssse3"
    else
      "x86-64"
    end

    system "make", "-C", "src", "build", "ARCH=#{arch}", "largeboards=yes"
    bin.install "src/stockfish" => "fairy-stockfish"
  end

  test do
    system bin/"fairy-stockfish", "go", "depth", "20"
  end
end
