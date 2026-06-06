class Rav1e < Formula
  desc "Fastest and safest AV1 video encoder"
  homepage "https://github.com/xiph/rav1e"
  url "https://github.com/xiph/rav1e/archive/refs/tags/v0.8.1.tar.gz"
  sha256 "06d1523955fb6ed9cf9992eace772121067cca7e8926988a1ee16492febbe01e"
  license "BSD-2-Clause"
  compatibility_version 1
  head "https://github.com/xiph/rav1e.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "20e1436c67a719ed78014e2c2c97a8814c13a2262cc070fbed06497dee741e32"
  end

  depends_on "cargo-c" => :build
  depends_on "rust" => :build

  on_intel do
    depends_on "nasm" => :build
  end

  def install
    system "cargo", "install", *std_cargo_args
    system "cargo", "cinstall", "--jobs", ENV.make_jobs.to_s, "--release", "--prefix", prefix, "--libdir", lib
  end

  test do
    resource "homebrew-bus_qcif_7.5fps.y4m" do
      url "https://media.xiph.org/video/derf/y4m/bus_qcif_7.5fps.y4m"
      sha256 "1f5bfcce0c881567ea31c1eb9ecb1da9f9583fdb7d6bb1c80a8c9acfc6b66f6b"
    end

    testpath.install resource("homebrew-bus_qcif_7.5fps.y4m")
    system bin/"rav1e", "--tile-rows=2", "bus_qcif_7.5fps.y4m", "--output=bus_qcif_15fps.ivf"
  end
end
