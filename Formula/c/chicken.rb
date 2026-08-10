class Chicken < Formula
  desc "Compiler for the Scheme programming language"
  homepage "https://www.call-cc.org/"
  url "https://code.call-cc.org/releases/6.0.0/chicken-6.0.0.tar.gz"
  sha256 "92835552b1b687ad26737e429b5aba36510bf429f8816ec0f6d336c8cb41f443"
  license "BSD-3-Clause"
  head "https://code.call-cc.org/git/chicken-core.git", branch: "master"

  livecheck do
    url "https://code.call-cc.org/releases/current/"
    regex(/href=.*?chicken[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2f092c8ee15172f4755746afb8af8170f26034175981f5fc92acaf8dac8713e4"
  end

  conflicts_with "mono", because: "both install `csc`, `csi` binaries"

  def install
    ENV.deparallelize

    args = %W[
      PREFIX=#{prefix}
      C_COMPILER=#{ENV.cc}
      LIBRARIAN=ar
      ARCH=#{Hardware::CPU.arch.to_s.tr("_", "-")}
      LINKER_OPTIONS=-Wl,-rpath,#{rpath},-rpath,#{HOMEBREW_PREFIX}/lib
    ]

    if OS.mac?
      args << "POSTINSTALL_PROGRAM=install_name_tool"
      args << "PLATFORM=macosx"
    else
      args << "PLATFORM=linux"
    end

    system "make", *args
    system "make", "install", *args
  end

  test do
    assert_equal "25", shell_output("#{bin}/csi -e '(print (* 5 5))'").strip
    system bin/"csi", "-ne", "(import (chicken tcp))"
  end
end
