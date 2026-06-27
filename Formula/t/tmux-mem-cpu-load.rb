class TmuxMemCpuLoad < Formula
  desc "CPU, RAM memory, and load monitor for use with tmux"
  homepage "https://github.com/thewtex/tmux-mem-cpu-load"
  url "https://github.com/thewtex/tmux-mem-cpu-load/archive/refs/tags/v3.8.3.tar.gz"
  sha256 "ea7a24802d6d1223831f749e68ef29c07c9c5e45dff570022f844ce37eb56c85"
  license "Apache-2.0"
  head "https://github.com/thewtex/tmux-mem-cpu-load.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "96a43f1966e939479b37cc410b9d8675d197f4a11c9cae24bae54f14f97b492f"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"tmux-mem-cpu-load"
  end
end
