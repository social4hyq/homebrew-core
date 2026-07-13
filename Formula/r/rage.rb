class Rage < Formula
  desc "Simple, modern, secure file encryption"
  homepage "https://str4d.xyz/rage"
  url "https://github.com/str4d/rage/archive/refs/tags/v0.12.0.tar.gz"
  sha256 "fb5255ff9faa944a15a128f812499cd5c08e6155790e284af34c914cbc3d0103"
  license any_of: ["MIT", "Apache-2.0"]
  head "https://github.com/str4d/rage.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e839460f7582687215204201121efdbe048d2c8f291fc66ec515083f375a0572"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "./rage")

    src_dir = "target/release/completions"
    bash_completion.install "#{src_dir}/rage.bash" => "rage"
    fish_completion.install "#{src_dir}/rage.fish"
    zsh_completion.install "#{src_dir}/_rage"
    bash_completion.install "#{src_dir}/rage-keygen.bash" => "rage-keygen"
    fish_completion.install "#{src_dir}/rage-keygen.fish"
    zsh_completion.install "#{src_dir}/_rage-keygen"

    man.install Dir["target/release/manpages/*"]
  end

  test do
    # Test key generation
    system bin/"rage-keygen", "-o", testpath/"output.txt"
    assert_path_exists testpath/"output.txt"

    # Test encryption
    (testpath/"test.txt").write("Hello World!\n")
    system bin/"rage", "-r", "age1y8m84r6pwd4da5d45zzk03rlgv2xr7fn9px80suw3psrahul44ashl0usm",
      "-o", testpath/"test.txt.age", testpath/"test.txt"
    assert_path_exists testpath/"test.txt.age"
    assert_equal "age-encryption.org/v1", File.open(testpath/"test.txt.age", &:gets).chomp

    # Test decryption
    (testpath/"test.key").write("AGE-SECRET-KEY-1TRYTV7PQS5XPUYSTAQZCD7DQCWC7Q77YJD7UVFJRMW4J82Q6930QS70MRX\n")
    assert_equal "Hello World!", shell_output("#{bin}/rage -d -i #{testpath}/test.key #{testpath}/test.txt.age").strip
  end
end
