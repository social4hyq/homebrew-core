class Ipbt < Formula
  desc "Program for recording a UNIX terminal session"
  homepage "https://www.chiark.greenend.org.uk/~sgtatham/ipbt/"
  url "https://www.chiark.greenend.org.uk/~sgtatham/ipbt/ipbt-20260410.a852474.tar.gz"
  version "20260410"
  sha256 "0713f515794643d48c88e79429dc392741e2ae15093b8d92bfc189110228406a"
  license "MIT"

  livecheck do
    url :homepage
    regex(/href=.*?ipbt[._-]v?(\d+(?:\.\d+)*)(?:[._-][\da-z]+)?\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b43fee1082746c6d7143f2d9f81e5bf72280436bc23b7e821750a859f0b9c551"
  end

  depends_on "cmake" => :build

  uses_from_macos "ncurses"

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    system bin/"ipbt"
  end
end
