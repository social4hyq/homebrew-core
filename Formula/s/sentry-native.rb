class SentryNative < Formula
  desc "Sentry SDK for C, C++ and native applications"
  homepage "https://docs.sentry.io/platforms/native/"
  url "https://github.com/getsentry/sentry-native/archive/refs/tags/0.16.8.tar.gz"
  sha256 "52cfd10b118985f6f840bac47d4e7ea1c9095b3222513d45317d52000920f69f"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "58d2d6e1f72677c9ff40038c85a448f389d5584fe4a3db9e3a07ae2dfaa81544"
  end

  depends_on "cmake" => :build

  uses_from_macos "curl"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # No recent tagged releases, use the latest commit
  resource "breakpad" do
    url "https://github.com/getsentry/breakpad.git",
        revision: "47d70322c848012ed801e36841767d7ffb79412d"
  end

  # No recent tagged releases, use the latest commit
  resource "crashpad" do
    url "https://github.com/getsentry/crashpad/archive/aae505d3daf73e8a48136ccc7398663f16096712.tar.gz"
    sha256 "cfc713e322f1ec7c9d963a9e25b176937464a39a7e95826ffe588cd0bb9bad62"
  end

  resource "crashpad/third_party/mini_chromium/mini_chromium" do
    url "https://github.com/getsentry/mini_chromium/archive/bcc80d6edf8b49d9bbe7a06fff308c222287b112.tar.gz"
    sha256 "009adf4cce8d3aba9e8d5ecd802cdc60eb87d271a3fb5f356c453b4a4122b219"
  end

  resource "crashpad/third_party/lss/lss" do
    url "https://chromium.googlesource.com/linux-syscall-support.git",
        revision: "9719c1e1e676814c456b55f5f070eabad6709d31"
  end

  # No recent tagged releases, use the latest commit
  resource "libunwindstack-ndk" do
    url "https://github.com/getsentry/libunwindstack-ndk.git",
        revision: "284202fb1e42dbeba6598e26ced2e1ec404eecd1"
  end

  resource "third-party/lss" do
    url "https://chromium.googlesource.com/linux-syscall-support.git",
        tag:      "v2024.02.01",
        revision: "ed31caa60f20a4f6569883b2d752ef7522de51e0"
  end

  def install
    resources.each { |r| r.stage buildpath/"external"/r.name }
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <sentry.h>
      int main() {
        sentry_options_t *options = sentry_options_new();
        sentry_options_set_dsn(options, "https://ABC.ingest.us.sentry.io/123");
        sentry_init(options);
        sentry_close();
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{HOMEBREW_PREFIX}/include", "-L#{HOMEBREW_PREFIX}/lib", "-lsentry", "-o", "test"
    system "./test"
  end
end
