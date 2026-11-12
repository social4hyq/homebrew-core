class Cmake < Formula
  desc "Cross-platform make"
  homepage "https://www.cmake.org/"
  url "https://github.com/Kitware/CMake/releases/download/v4.4.5/cmake-4.4.5.tar.gz"
  mirror "http://fresh-center.net/linux/misc/cmake-4.4.5.tar.gz"
  mirror "http://fresh-center.net/linux/misc/legacy/cmake-4.4.5.tar.gz"
  sha256 "a0c54c88abb8078dd8eccadb717fc6bb194bf18e7d44c86309910288886e04e2"
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

  uses_from_macos "ncurses"

  on_linux do
    depends_on "openssl@4"
  end

  deny_network_access!

  if OS.ohos?
    # OHOS defines __linux__ but does not provide the CPU-affinity APIs that
    # CMake and its bundled libuv probe for, so disable those code paths.
    patch do
      file "Patches/cmake/0001-disable-cpu-affinity.patch"
    end
    patch do
      file "Patches/cmake/0002-readdir-errno.patch"
    end
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
    # OHOS keeps its CA bundle at this fixed path, so point the bundled curl at it.
    cmake_args << "-DCURL_CA_BUNDLE=/etc/ssl/certs/cacert.pem" if OS.ohos?

    # On OHOS, headers and libs are in the SDK sysroot.
    # Tell find_* commands to also search there via FIND_ROOT_PATH.
    if OS.ohos?
      resource_dir = Utils.safe_popen_read("/usr/bin/clang", "-print-resource-dir").strip
      sysroot = File.expand_path("../../../../sysroot", resource_dir)
      if File.directory?(sysroot)
        cmake_args << "-DCMAKE_FIND_ROOT_PATH=#{sysroot}"
        cmake_args << "-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH"
      end
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
    mkdir "glob-input" do
      %w[first second third].each { |name| touch name }
    end
    (testpath/"glob.cmake").write <<~CMAKE
      file(GLOB entries "#{testpath}/glob-input/*")
      list(LENGTH entries count)
      if(NOT count EQUAL 3)
        message(FATAL_ERROR "Expected 3 directory entries, got ${count}")
      endif()
    CMAKE
    system bin/"cmake", "-P", "glob.cmake"

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
