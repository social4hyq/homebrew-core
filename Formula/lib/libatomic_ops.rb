class LibatomicOps < Formula
  desc "Implementations for atomic memory update operations"
  homepage "https://github.com/bdwgc/libatomic_ops/"
  url "https://github.com/bdwgc/libatomic_ops/releases/download/v7.10.0/libatomic_ops-7.10.0.tar.gz"
  sha256 "0db3ebff755db170f65e74a64ec4511812e9ee3185c232eeffeacd274190dfb0"
  license all_of: ["GPL-2.0-or-later", "MIT"]
  head "https://github.com/bdwgc/libatomic_ops.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "53e99790ce73cc73b55b09809d224c2af961e3593e8744fdcdb564ff5324eb9d"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    "-Dbuild_tests=ON",
                    *std_cmake_args,
                    "-DBUILD_TESTING=ON" # Pass this last to override `std_cmake_args`
    system "cmake", "--build", "build"
    system "ctest", "--test-dir", "build",
                    "--parallel", ENV.make_jobs,
                    "--rerun-failed",
                    "--output-on-failure"
    system "cmake", "--install", "build"
  end

  def test
    system "true"
  end
end
