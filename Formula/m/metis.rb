class Metis < Formula
  desc "Programs that partition graphs and order matrices"
  homepage "https://karypis.github.io/glaros/software/metis/overview.html"
  url "https://karypis.github.io/glaros/files/sw/metis/metis-5.1.0.tar.gz"
  mirror "https://ftp.mcs.anl.gov/pub/pdetools/spack-pkgs/metis-5.1.0.tar.gz"
  sha256 "76faebe03f6c963127dbb73c13eab58c9a3faeae48779f049066a21c087c5db2"
  license "Apache-2.0"

  livecheck do
    url :homepage
    regex(%r{href=.*?/metis[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3db6e3db38c1e0ac5402b1adf92df9d1d6245507e5d14ec423c753bc01be5c4b"
  end

  depends_on "cmake" => :build

  def install
    # Fix build with CMake 4.0+.
    inreplace "CMakeLists.txt",
              "cmake_minimum_required(VERSION 2.8)",
              "cmake_minimum_required(VERSION 3.10)"
    ENV.append "LDFLAGS", "-Wl,-rpath,#{rpath}"

    system "make", "config", "prefix=#{prefix}", "shared=1"
    system "make", "install"

    pkgshare.install "graphs"
  end

  test do
    ["4elt", "copter2", "mdual"].each do |g|
      cp pkgshare/"graphs/#{g}.graph", testpath
      system bin/"graphchk", "#{g}.graph"
      system bin/"gpmetis", "#{g}.graph", "2"
      system bin/"ndmetis", "#{g}.graph"
    end
    cp [pkgshare/"graphs/test.mgraph", pkgshare/"graphs/metis.mesh"], testpath
    system bin/"gpmetis", "test.mgraph", "2"
    system bin/"mpmetis", "metis.mesh", "2"
  end
end
