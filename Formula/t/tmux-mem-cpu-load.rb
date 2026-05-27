class TmuxMemCpuLoad < Formula
  desc "CPU, RAM memory, and load monitor for use with tmux"
  homepage "https://github.com/thewtex/tmux-mem-cpu-load"
  url "https://github.com/thewtex/tmux-mem-cpu-load/archive/refs/tags/v3.8.2.tar.gz"
  sha256 "c433e396050a821f915f3fd1e7d932b46204def8d59a46fce4f486b1b4ebef2e"
  license "Apache-2.0"
  head "https://github.com/thewtex/tmux-mem-cpu-load.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aa1c85b7d0817a578220691c78f8efac27bc4d38e991c5265cc796d243f3ccb4"
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
