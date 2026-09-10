class Fish < Formula
  desc "User-friendly command-line shell for UNIX-like operating systems"
  homepage "https://fishshell.com"
  url "https://github.com/fish-shell/fish-shell/releases/download/4.9.3/fish-4.9.3.tar.xz"
  sha256 "20998a25f73217ddcc19f499055fd587e9912d1ad6e7109120fbcf2871f0b98c"
  license "GPL-2.0-only"
  revision 1
  compatibility_version 1
  head "https://github.com/fish-shell/fish-shell.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  pour_bottle? only_if: :default_prefix

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "13835028aa3f7f1f8da140618138a723ee7b775c31f1cc6a29450c4826bedb5e"
  end

  depends_on "cmake" => :build
  depends_on "rust" => :build
  depends_on "sphinx-doc" => :build
  depends_on "pcre2"

  patch do
    file "Patches/fish/sscanf_fix.patch"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args,
                    "-DCMAKE_INSTALL_SYSCONFDIR=#{etc}",
                    "-DWITH_DOCS=ON",
                    "-Dextra_functionsdir=#{HOMEBREW_PREFIX}/share/fish/vendor_functions.d",
                    "-Dextra_completionsdir=#{HOMEBREW_PREFIX}/share/fish/vendor_completions.d",
                    "-Dextra_confdir=#{HOMEBREW_PREFIX}/share/fish/vendor_conf.d"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  def post_install
    (pkgshare/"vendor_functions.d").mkpath
    (pkgshare/"vendor_completions.d").mkpath
    (pkgshare/"vendor_conf.d").mkpath
  end

  test do
    system bin/"fish", "-c", "echo"
    output = shell_output("#{bin}/fish -c 'set --show fish_function_path'")
    assert_match "#{HOMEBREW_PREFIX}/share/fish/vendor_functions.d", output
  end
end
