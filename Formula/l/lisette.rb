class Lisette < Formula
  desc "Language inspired by Rust that compiles to Go"
  homepage "https://lisette.run"
  url "https://github.com/ivov/lisette/archive/refs/tags/lisette-v0.3.0.tar.gz"
  sha256 "603240495851c8975e29377f2131ad8eb34130811932b596dd002f2664205e39"
  license "MIT"
  head "https://github.com/ivov/lisette.git", branch: "main"

  livecheck do
    url :stable
    regex(/^lisette[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "16555310afab575a6b175d16a7f5ba6b5d13fb3208ae1a804d6ae9a63eb97770"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/cli")

    generate_completions_from_executable(bin/"lis", "complete", shells: [:bash, :zsh, :fish])
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/lis version")

    (testpath/"hello.lis").write <<~LIS
      import "go:fmt"

      fn main() {
        fmt.Println("hello")
      }
    LIS
    system bin/"lis", "check", testpath/"hello.lis"
  end
end
