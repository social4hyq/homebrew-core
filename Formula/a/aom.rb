class Aom < Formula
  desc "Codec library for encoding and decoding AV1 video streams"
  homepage "https://aomedia.googlesource.com/aom"
  url "https://aomedia.googlesource.com/aom.git",
      tag:      "v3.14.0",
      revision: "047d8cf6168feafe1300eb6902000dd1a03d5549"
  license "BSD-2-Clause"
  head "https://aomedia.googlesource.com/aom.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b97049e5fe90ca2c0931a831b7e4bb0fc8400858a1027090a3ef46b67e325ea7"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "libvmaf"

  on_intel do
    depends_on "nasm" => :build
  end

  def install
    ENV.runtime_cpu_detection

    args = %W[
      -DCMAKE_INSTALL_RPATH=#{rpath}
      -DENABLE_DOCS=OFF
      -DENABLE_EXAMPLES=ON
      -DENABLE_TESTDATA=OFF
      -DENABLE_TESTS=OFF
      -DENABLE_TOOLS=OFF
      -DBUILD_SHARED_LIBS=ON
      -DCONFIG_TUNE_VMAF=1
    ]
    # OpenHarmony lacks GNU as; use clang's integrated assembler
    args << "-DCMAKE_ASM_COMPILER=#{ENV.cc}" if OS.linux? 
    
    system "cmake", "-S", ".", "-B", "brewbuild", *args, *std_cmake_args
    system "cmake", "--build", "brewbuild"
    system "cmake", "--install", "brewbuild"
  end

  test do
    resource "homebrew-bus_qcif_15fps.y4m" do
      url "https://media.xiph.org/video/derf/y4m/bus_qcif_15fps.y4m"
      sha256 "868fc3446d37d0c6959a48b68906486bd64788b2e795f0e29613cbb1fa73480e"
    end

    testpath.install resource("homebrew-bus_qcif_15fps.y4m")

    system bin/"aomenc", "--webm",
                         "--tile-columns=2",
                         "--tile-rows=2",
                         "--cpu-used=8",
                         "--output=bus_qcif_15fps.webm",
                         "bus_qcif_15fps.y4m"

    system bin/"aomdec", "--output=bus_qcif_15fps_decode.y4m",
                         "bus_qcif_15fps.webm"
  end
end
