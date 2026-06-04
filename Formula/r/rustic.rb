class Rustic < Formula
  desc "Fast, encrypted, and deduplicated backups powered by Rust"
  homepage "https://rustic.cli.rs"
  url "https://github.com/rustic-rs/rustic/archive/refs/tags/v0.11.3.tar.gz"
  sha256 "abbafea18ea56f486a68f186bb139b0e8e8d002bb5cd897ed148cf7817a8ed73"
  license "Apache-2.0"
  head "https://github.com/rustic-rs/rustic.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c5f52b80dd2637fca50f640e2fd12f6bb01f8bfa2c44d8c3c25a77b814884b5a"
  end

  depends_on "cmake" => :build
  depends_on "rust" => :build

  def install
    ENV["AWS_LC_SYS_NO_JITTER_ENTROPY"] = "1"
    system "cargo", "install", *std_cargo_args
    generate_completions_from_executable(bin/"rustic", "completions")
  end

  test do
    mkdir testpath/"rustic_repo"
    ENV["RUSTIC_REPOSITORY"] = testpath/"rustic_repo"
    ENV["RUSTIC_PASSWORD"] = "test"

    (testpath/"testfile").write("test test test")

    system bin/"rustic", "init"
    system bin/"rustic", "backup", "testfile"

    system bin/"rustic", "restore", "latest:testfile", testpath/"testfile_restore"
    assert compare_file testpath/"testfile", testpath/"testfile_restore"
  end
end
