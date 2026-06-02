class Tth < Formula
  desc "TeX/LaTeX to HTML converter"
  homepage "http://silas.psfc.mit.edu/tth/"
  url "https://downloads.sourceforge.net/project/tth/tth4.16.tar.gz"
  sha256 "b0e118d49a37e06598c1e2b524ea352ceabf064afef25acf02b556229ee43512"
  license "GPL-2.0-only"

  livecheck do
    url :stable
    regex(%r{url=.*?/tth[._-]?v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dbd510899e558f579012f30fb58c59faa0ba2871ca07a9fb4201324fd80e6c09"
  end

  uses_from_macos "flex" => :build

  def install
    system "make", "tth.c"
    system ENV.cc, "-o", "tth", "tth.c"
    bin.install %w[tth latex2gif ps2gif]
    man1.install "tth.1"
  end

  test do
    assert_match(/version #{version}/, pipe_output(bin/"tth", ""))
  end
end
