class Flvmeta < Formula
  desc "Manipulate Adobe flash video files (FLV)"
  homepage "https://flvmeta.com/"
  url "https://github.com/noirotm/flvmeta/archive/refs/tags/v1.2.2.tar.gz"
  sha256 "59371e286168d6e5c4647d3575c01bcbb30147c4916eb69e10f38cdbc1c5546d"
  license "GPL-2.0-or-later"
  head "https://github.com/noirotm/flvmeta.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6119a0df3ed8c52c35b0f69db7d8c6ef1b82f00735ff3d0c3b30feea6342045d"
  end

  # adobe flash player EOL 12/31/2020, https://www.adobe.com/products/flashplayer/end-of-life-alternative.html
  deprecate! date: "2025-03-21", because: :unmaintained
  disable! date: "2026-03-21", because: :unmaintained

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_POLICY_VERSION_MINIMUM=3.5", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"flvmeta", "-V"
  end
end
