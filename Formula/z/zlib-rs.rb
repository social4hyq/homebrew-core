class ZlibRs < Formula
  desc "C API for zlib-rs"
  homepage "https://github.com/trifectatechfoundation/zlib-rs/tree/main/libz-rs-sys-cdylib#libz-rs-sys-cdylib"
  url "https://github.com/trifectatechfoundation/zlib-rs/archive/refs/tags/v0.6.8.tar.gz"
  sha256 "10c2faddc8f0f150a4917c9641f49e350cb4c1ce187962bc88e7f7ce1411837e"
  license "Zlib"
  head "https://github.com/trifectatechfoundation/zlib-rs.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "90b4eeac5bc34295f42ae9ceacfb539d512902d2804883c350bdaad95d258993"
  end

  depends_on "cargo-c" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat" => :test
  end

  def install
    # https://github.com/trifectatechfoundation/zlib-rs/tree/main/libz-rs-sys-cdylib#-cllvm-args-enable-dfa-jump-thread
    ENV.append_to_rustflags "-Cllvm-args=-enable-dfa-jump-thread"
    cd "libz-rs-sys-cdylib" do
      system "cargo", "cinstall", "--jobs", ENV.make_jobs.to_s, "--prefix", prefix, "--libdir", lib, "--release"
    end
  end

  test do
    # https://zlib.net/zlib_how.html
    resource "zpipe.c" do
      url "https://raw.githubusercontent.com/trifectatechfoundation/zlib-rs/refs/tags/v0.6.2/libz-rs-sys-cdylib/zpipe.c"
      sha256 "4fd3b0b41fb8da462d28da5b3e214cc6f4609205b38aaee1e20524b57124f338"
    end

    testpath.install resource("zpipe.c")
    ENV.append_to_cflags "-I#{Formula["zlib-ng-compat"].opt_include}" if OS.linux?
    system ENV.cc, "zpipe.c", *ENV.cflags.to_s.split, "-L#{lib}", "-lz_rs", "-o", "zpipe"

    text = "Hello, Homebrew!"
    compressed = pipe_output("./zpipe", text, 0)
    assert_equal text, pipe_output("./zpipe -d", compressed, 0)
  end
end
