class Drafter < Formula
  desc "Native C/C++ API Blueprint Parser"
  homepage "https://apiblueprint.org/"
  url "https://github.com/apiaryio/drafter/releases/download/v5.1.0/drafter-v5.1.0.tar.gz"
  sha256 "b3f60d9e77ace0d40d32b892b99852d3ed92e2fd358abd7f43d813c8dc473913"
  license "MIT"
  head "https://github.com/apiaryio/drafter.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "4498a8e48139ed39d64e9d7cc9fc1256e036d6475b385a47082ce79e4a20642c"
  end

  deprecate! date: "2024-12-04", because: :repo_archived
  disable! date: "2025-12-04", because: :repo_archived

  depends_on "cmake" => :build

  # patch release version
  patch do
    url "https://github.com/apiaryio/drafter/commit/481d0ba83370d2cd45aa1979308cac4c2dbd3ab3.patch?full_index=1"
    sha256 "3c3579ab3c0ae71a4449f547b734023b40a872b82ea81a8ccc0961f1d47e9a25"
  end

  def install
    # Fix to error: no member named 'swap' in namespace 'std'
    if OS.mac? && DevelopmentTools.clang_build_version >= 1700
      inreplace "packages/boost/boost/move/adl_move_swap.hpp",
                "#define BOOST_MOVE_ADL_MOVE_SWAP_HPP",
                "#define BOOST_MOVE_ADL_MOVE_SWAP_HPP\n#include <utility>"
    end

    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_POLICY_VERSION_MINIMUM=3.5", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"api.apib").write <<~EOS
      # Homebrew API [/brew]

      ## Retrieve All Formula [GET /Formula]
      + Response 200 (application/json)
        + Attributes (array)
    EOS
    assert_equal "OK.", shell_output("#{bin}/drafter -l api.apib 2>&1").strip

    assert_match version.to_s, shell_output("#{bin}/drafter --version")
  end
end
