class Qhull < Formula
  desc "Computes convex hulls in n dimensions"
  homepage "http://www.qhull.org/"
  url "https://deb.debian.org/debian/pool/main/q/qhull/qhull_2020.2.orig.tar.gz"
  mirror "http://www.qhull.org/download/qhull-2020-src-8.0.2.tgz"
  sha256 "b5c2d7eb833278881b952c8a52d20179eab87766b00b865000469a45c1838b7e"
  license "Qhull"
  compatibility_version 1
  head "https://github.com/qhull/qhull.git", branch: "master"

  # It's necessary to match the version from the link text, as the filename
  # only contains the year (`2020`), not a full version like `2020.2`.
  livecheck do
    url "http://www.qhull.org/download/"
    regex(/href=.*?qhull[._-][^"' >]+?[._-]src[^>]*?\.t[^>]+?>[^<]*Qhull v?(\d+(?:\.\d+)*)/i)
  end

  no_autobump! because: :incompatible_version_format

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "44eaf6bcc8498be2616c24e78a720c084d4b89b5264148c4f0b43a1a37ffab22"
  end

  depends_on "cmake" => :build

  def install
    # Workaround for CMake 4.0+
    ENV["CMAKE_POLICY_VERSION_MINIMUM"] = "3.5"
    odie "Remove cmake workaround" if build.stable? && version > "2020.2"

    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    input = shell_output("#{bin}/rbox c D2")
    output = pipe_output("#{bin}/qconvex s n 2>&1", input, 0)
    assert_match "Number of facets: 4", output
  end
end
