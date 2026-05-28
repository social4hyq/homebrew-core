class Rure < Formula
  desc "C API for RUst's REgex engine"
  homepage "https://github.com/rust-lang/regex/tree/HEAD/regex-capi"
  url "https://static.crates.io/crates/rure/rure-0.2.5.crate"
  sha256 "8af70744723e3d5b88fec7869518bbd17883b7d9944f67c9b4a69ae4ed90dc9a"
  license all_of: [
    "Unicode-TOU",
    any_of: ["Apache-2.0", "MIT"],
  ]
  version_scheme 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d8213b65e8ccda040e554f86b68418f36525db1a20ba43f40f5a19c10d2ac3d1"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "build", "--jobs", ENV.make_jobs, "--lib", "--release"
    include.install "include/rure.h"
    lib.install "target/release/#{shared_library("librure")}"
    lib.install "target/release/librure.a"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <rure.h>
      int main(int argc, char **argv) {
        rure *re = rure_compile_must("a");
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lrure", "-o", "test"
    system "./test"
  end
end
