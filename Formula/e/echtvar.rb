class Echtvar < Formula
  desc "Rapid variant annotation and filtering"
  homepage "https://academic.oup.com/nar/advance-article/doi/10.1093/nar/gkac931/6775383"
  url "https://github.com/brentp/echtvar/archive/refs/tags/v0.2.4.tar.gz"
  sha256 "e4d04d16d9c8e02aa9c216d7c7173e4d35ed3a9f848d05e5908d60e74b5c128b"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6d76e6225a32cd561bcee438bc47a2c8f7baf136dc4cd0a4721029ef7ea7e116"
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "python@3.14" => :test
  depends_on "openssl@3"

  uses_from_macos "bzip2"

  def install
    # portable_simd feature requires nightly.
    # Use a stable-Rust stub to keep the CLI buildable without nightly.
    ENV["RUSTC_BOOTSTRAP"] = "1"

    system "cargo", "install", *std_cargo_args
    pkgshare.install "tests"
  end

  test do
    cp_r pkgshare/"tests/.", testpath
    system "python3.14", "make-vcf.py", "2"
    system bin/"echtvar", "encode", "test.zip", "test0.hjson", "generated-subset0.vcf"
    assert_path_exists "test.zip"
  end
end
