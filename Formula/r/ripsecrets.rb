class Ripsecrets < Formula
  desc "Prevent committing secret keys into your source code"
  homepage "https://github.com/sirwart/ripsecrets"
  url "https://github.com/sirwart/ripsecrets/archive/refs/tags/v0.1.11.tar.gz"
  sha256 "786c1b7555c1f9562d7eb3994d932445ab869791be65bc77b8bd1fbbae3890b8"
  license "MIT"
  head "https://github.com/sirwart/ripsecrets.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c0f898965c1dc9bcb50da62f26c6ca0dc287a5cc488e07393da2b79b1c58d218"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    out_dir = Dir["target/release/build/ripsecrets-*/out"].first
    bash_completion.install "#{out_dir}/ripsecrets.bash" => "ripsecrets"
    fish_completion.install "#{out_dir}/ripsecrets.fish"
    zsh_completion.install "#{out_dir}/_ripsecrets"
    man1.install "#{out_dir}/ripsecrets.1"
  end

  test do
    # Generate a real-looking key
    keyspace = "A".upto("Z").to_a + "a".upto("z").to_a + "0".upto("9").to_a + ["_"]
    fake_key = Array.new(36).map { keyspace.sample }
    # but mark it as allowed to test more of the program
    (testpath/"test.txt").write("ghp_#{fake_key.join} # pragma: allowlist secret")

    system bin/"ripsecrets", (testpath/"test.txt")
  end
end
