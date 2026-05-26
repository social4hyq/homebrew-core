class MagicWormholeRs < Formula
  desc "Rust implementation of Magic Wormhole, with new features and enhancements"
  homepage "https://github.com/magic-wormhole/magic-wormhole.rs"
  url "https://github.com/magic-wormhole/magic-wormhole.rs/archive/refs/tags/0.8.1.tar.gz"
  sha256 "90e8b1d7270a4c251f78376e10948c994df1a559152eca7eedd4aecbf70b70d9"
  license "EUPL-1.2"
  head "https://github.com/magic-wormhole/magic-wormhole.rs.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0687e4dea0b95e82abf83e8398d46adbd31302743280e64031377988f56ebd5d"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "cli")

    generate_completions_from_executable(bin/"wormhole-rs", "completion")
  end

  test do
    n = rand(1e6)
    pid = spawn bin/"wormhole-rs", "send", "--code=#{n}-homebrew-test", test_fixtures("test.svg")
    begin
      sleep 1
      exec bin/"wormhole-rs", "receive", "--noconfirm", "#{n}-homebrew-test"
      assert_path_exists testpath/"received.svg"
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
