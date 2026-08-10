class Oxipng < Formula
  desc "Multithreaded PNG optimizer written in Rust"
  homepage "https://github.com/oxipng/oxipng"
  url "https://github.com/oxipng/oxipng/archive/refs/tags/v10.2.0.tar.gz"
  sha256 "0d0da5f245ed3a669bce63d3ca368d476bae67b0014a927c00df912c9d964a44"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "98e0b18e4e4b69bada1ed1889972f489c345e4b3084e76a2d44526f4342af457"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
    system "cargo", "run",
           "--manifest-path", "xtask/Cargo.toml",
           "--jobs", ENV.make_jobs.to_s,
           "--locked", "--", "mangen"

    man1.install "target/xtask/mangen/manpages/oxipng.1"
  end

  test do
    system bin/"oxipng", "--dry-run", test_fixtures("test.png")
  end
end
