class BcGh < Formula
  desc "Implementation of Unix dc and POSIX bc with GNU and BSD extensions"
  homepage "https://github.com/gavinhoward/bc"
  url "https://github.com/gavinhoward/bc/releases/download/7.0.3/bc-7.0.3.tar.xz"
  sha256 "91eb74caed0ee6655b669711a4f350c25579778694df248e28363318e03c7fc4"
  license "BSD-2-Clause"
  head "https://github.com/gavinhoward/bc.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3cce449da335cdfbf39fb0ff79e567bd39412e31ef6e86992da04cd32220e9b5"
  end

  keg_only :provided_by_macos # since Ventura

  depends_on "pkgconf" => :build

  uses_from_macos "libedit"

  conflicts_with "bc", because: "both install `bc` and `dc` binaries"

  def install
    # https://github.com/gavinhoward/bc#recommended-optimizations
    ENV.O3
    ENV.append "CFLAGS", "-flto"

    # NOTE: `--predefined-build-type` should be kept first to avoid overwriting later args
    system "./configure.sh", "--predefined-build-type=GNU",
                             "--disable-generated-tests",
                             "--disable-problematic-tests",
                             "--disable-nls",
                             "--enable-editline",
                             "--prefix=#{prefix}"
    system "make"
    system "make", "install"
  end

  test do
    system bin/"bc", "--version"
    assert_match "2", pipe_output(bin/"bc", "1+1\n", 0)
  end
end
