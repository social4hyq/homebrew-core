class Csmith < Formula
  desc "Generates random C programs conforming to the C99 standard"
  homepage "https://github.com/csmith-project/csmith"
  url "https://github.com/csmith-project/csmith/archive/refs/tags/csmith-2.3.0.tar.gz"
  sha256 "9d024a6b202f6a1b9e01351218a85888c06b67b837fe4c6f8ef5bd522fae098c"
  license "BSD-2-Clause"
  head "https://github.com/csmith-project/csmith.git", branch: "master"

  livecheck do
    url :stable
    regex(/^(?:csmith[._-])?v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3d0133ec62282908987c90f5bc7dd4157ffc2f0966ee62c4d1d44c86da7340c2"
  end

  uses_from_macos "m4" => :build

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    # Workaround for newer Clang until upstream fix
    # https://github.com/csmith-project/csmith/issues/163
    # https://github.com/csmith-project/csmith/issues/177
    # https://github.com/csmith-project/csmith/pull/165
    ENV.append_to_cflags "-Wno-enum-constexpr-conversion" if DevelopmentTools.clang_build_version >= 1700

    system "./configure", *std_configure_args
    system "make"
    system "make", "install"
    mv "#{bin}/compiler_test.in", share
    (include/"csmith-#{version}/runtime").install Dir["runtime/*.h"]
  end

  def caveats
    <<~EOS
      It is recommended that you set the environment variable 'CSMITH_PATH' to
        #{include}/csmith-#{version}
    EOS
  end

  test do
    system bin/"csmith", "-o", "test.c"
  end
end
