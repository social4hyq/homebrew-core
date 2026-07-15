class Cmake < Formula
  desc "Cross-platform make"
  homepage "https://www.cmake.org/"
  url "https://github.com/Kitware/CMake/releases/download/v4.4.0/cmake-4.4.0.tar.gz"
  mirror "http://fresh-center.net/linux/misc/cmake-4.4.0.tar.gz"
  mirror "http://fresh-center.net/linux/misc/legacy/cmake-4.4.0.tar.gz"
  sha256 "65757f442fdd242e27f1728fc26dc0cba4164f7a0791a5c788631c00080369bc"
  license "BSD-3-Clause"
  revision 1
  compatibility_version 1
  head "https://gitlab.kitware.com/cmake/cmake.git", branch: "master"

  # The "latest" release on GitHub has been an unstable version before, and
  # there have been delays between the creation of a tag and the corresponding
  # release, so we check the website's downloads page instead.
  livecheck do
    url "https://cmake.org/download/"
    regex(/href=.*?cmake[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "38c5b9c21005784161fea0be3a222e78a69bca9030eabf04d511fc392034a250"
  end

  uses_from_macos "ncurses"

  on_linux do
    depends_on "openssl@3"
  end

  conflicts_with cask: "cmake-app"

  patch do
    file "Patches/cmake/0001-disable-cpu-affinity.patch"
  end

  def install
    args = %W[
      --prefix=#{prefix}
      --no-system-libs
      --parallel=#{ENV.make_jobs}
      --datadir=/share/cmake
      --docdir=/share/doc/cmake
      --mandir=/share/man
    ]
    if OS.mac?
      args += %w[
        --system-zlib
        --system-bzip2
        --system-curl
      ]
    end

    cmake_args = %W[
      -DCMake_INSTALL_BASH_COMP_DIR=#{bash_completion}
      -DCMake_INSTALL_EMACS_DIR=#{elisp}
      -DCMake_BUILD_LTO=OFF
    ]
    # On OHOS, headers and libs are in the SDK sysroot.
    # Tell find_* commands to also search there via FIND_ROOT_PATH.
    resource_dir = Utils.safe_popen_read("/usr/bin/clang", "-print-resource-dir").strip
    sysroot = File.expand_path("../../../../sysroot", resource_dir)
    if File.directory?(sysroot)
      cmake_args << "-DCMAKE_FIND_ROOT_PATH=#{sysroot}"
      cmake_args << "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH"
    end

    system "./bootstrap", *args, "--", *std_cmake_args, *cmake_args
    system "make"
    system "make", "install"

    # Move ctest completion because of problems with macOS system bash 3
    (share/"bash-completion/completions").install bash_completion/"ctest"
  end

  def caveats
    <<~EOS
      To install the CMake documentation, run:
        brew install cmake-docs
    EOS
  end

  test do
    (testpath/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required(VERSION #{version.major_minor})
      find_package(Ruby)
    CMAKE
    system bin/"cmake", "."

    # These should be supplied in a separate cmake-docs formula.
    refute_path_exists doc/"html"
    refute_path_exists man
  end
end
