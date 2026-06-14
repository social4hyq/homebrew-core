class Pmccabe < Formula
  desc "Calculate McCabe-style cyclomatic complexity for C/C++ code"
  homepage "https://gitlab.com/pmccabe/pmccabe"
  url "https://gitlab.com/pmccabe/pmccabe/-/archive/v2.9/pmccabe-v2.9.tar.bz2"
  sha256 "8b0e207c171bb3c8b9dcc226b85a8a8f1f87c98cc8e71e760a99c3058042ec48"
  license "GPL-2.0-or-later"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:[._]\d+)+[a-z]?)$/i)
    strategy :git do |tags, regex|
      tags.map { |tag| tag[regex, 1]&.tr("_", ".") }
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0d25901f0be4258f47008177509dc856ecaadf5edacd1a10508978a9e3e38faa"
  end

  def install
    ENV.append_to_cflags "-D__unix"

    system "make", "CFLAGS=#{ENV.cflags}"
    bin.install "pmccabe", "codechanges", "decomment", "vifn"
    man1.install Dir["*.1"]
  end

  test do
    assert_match "pmccabe #{version}", shell_output("#{bin}/pmccabe -V")
  end
end
