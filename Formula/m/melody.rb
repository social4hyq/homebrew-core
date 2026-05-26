class Melody < Formula
  desc "Language that compiles to regular expressions"
  homepage "https://yoav-lavi.github.io/melody/book"
  url "https://github.com/yoav-lavi/melody/archive/refs/tags/v0.20.0.tar.gz"
  sha256 "b0dd1b0ecc1af97f09f98a9a741e0dddbf92380c9980140140ff1b4262b9a44a"
  license any_of: ["Apache-2.0", "MIT"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1fbe41428c5fcaaecdd973c3bcda4bdf69cf92d8a8a3dd5db760dd1a0c2fb142"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/melody_cli")

    generate_completions_from_executable(bin/"melody", "--generate-completions")
  end

  test do
    mdy = "regex.mdy"
    File.write mdy, '"#"; some of <word>;'
    assert_match "#\\w+", shell_output("#{bin}/melody --no-color #{mdy}")
  end
end
