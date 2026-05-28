class Bkt < Formula
  desc "CLI utility for caching the output of subprocesses"
  # Original homepage `https://www.bkt.rs` is down
  homepage "https://github.com/dimo414/bkt"
  url "https://github.com/dimo414/bkt/archive/refs/tags/0.8.2.tar.gz"
  sha256 "d9128a13070ebc564bcc70210062bdd60eb757fd0f5d075c50e9aa7f714c6562"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b3d2d3bb17948c88f83ebd8b016ba35d0a25faedf21aed5f1a51a73e3f1b48b4"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    # Make sure date output is cached between runs
    output1 = shell_output("#{bin}/bkt --ttl=1m -- date +%s.%N")
    sleep(1)
    assert_equal output1, shell_output("#{bin}/bkt --ttl=1m -- date +%s.%N")
  end
end
