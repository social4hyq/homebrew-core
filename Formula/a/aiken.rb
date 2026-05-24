class Aiken < Formula
  desc "Modern smart contract platform for Cardano"
  homepage "https://aiken-lang.org/"
  url "https://github.com/aiken-lang/aiken/archive/refs/tags/v1.1.21.tar.gz"
  sha256 "c6bbdba11a37a6452d6a00c6fee9473264b757475912c4dfd9c3fd18ea60ed4c"
  license "Apache-2.0"
  revision 1
  head "https://github.com/aiken-lang/aiken.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e7671b4fb69fc80b728ea29cb63491d506a3cf0c05b7b691e244a621d3783b4c"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@4"
  end

  # Backport openssl part 1
  patch do
    url "https://github.com/aiken-lang/aiken/commit/d5aba83a115439384ecd5b4c398c33baf33f7a77.patch?full_index=1"
    sha256 "499e4f309d5a0ea7c047b0d05c8933019d616b6ec831a5dbaf73ebb982c06bf4"
  end

  # Backport openssl 4 support https://github.com/aiken-lang/aiken/pull/1312
  patch do
    url "https://github.com/aiken-lang/aiken/commit/b1756f6311d383c079dfd976c2a2068aedbf922e.patch?full_index=1"
    sha256 "423ed0c5a3453f3870f1984cb67c30806e3f506fbdfe5ddbd7955431858a0cb9"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/aiken")

    generate_completions_from_executable(bin/"aiken", "completion")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/aiken --version")

    system bin/"aiken", "new", "brewtest/hello"
    assert_path_exists testpath/"hello/README.md"
    assert_match "brewtest/hello", (testpath/"hello/aiken.toml").read
  end
end
