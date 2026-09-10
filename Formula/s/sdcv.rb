class Sdcv < Formula
  desc "StarDict Console Version"
  homepage "https://dushistov.github.io/sdcv/"
  url "https://github.com/Dushistov/sdcv/archive/refs/tags/v0.5.5.tar.gz"
  sha256 "4d2519e8f8479b9301dc91e9cda3e1eefef19970ece0e8c05f0c7b7ade5dc94b"
  license "GPL-2.0-or-later"
  revision 1
  version_scheme 1
  head "https://github.com/Dushistov/sdcv.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f47b12e8f3a553a1cc87095a3a61b071ea43a5fd0f9d4b5da5cd6e5c0481333a"
  end

  depends_on "cmake" => :build
  depends_on "gettext" => :build
  depends_on "pkgconf" => :build

  depends_on "glib"
  depends_on "readline"

  on_macos do
    depends_on "gettext"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # fix type mismatch and memory deallocation build errors
  # upstream PR ref, https://github.com/Dushistov/sdcv/pull/103
  patch do
    url "https://github.com/Dushistov/sdcv/commit/c2bb4e3fe51f9b9940440ea81d5d97b56d5582e7.patch?full_index=1"
    sha256 "70c4c826c2dcd4c0aad5fa8f27b7e079f4461cfbbb380b4726aa4dfd8fb75a1c"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build", "--target", "lang"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"sdcv", "-h"
  end
end
