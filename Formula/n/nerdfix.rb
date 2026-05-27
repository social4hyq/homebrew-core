class Nerdfix < Formula
  desc "Find/fix obsolete Nerd Font icons"
  homepage "https://github.com/loichyan/nerdfix"
  url "https://github.com/loichyan/nerdfix/archive/refs/tags/v0.4.2.tar.gz"
  sha256 "e56f648db6bfa9a08d4b2adbf3862362ff66010f32c80dc076c0c674b36efd3c"
  license any_of: ["MIT", "Apache-2.0"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a356a7522ea971149a13586ef422feb67d1b37513e8d5e22d7d018f8e2d196bd"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"nerdfix", "completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nerdfix --version")

    touch "test.txt"
    system bin/"nerdfix", "check", "test.txt"
  end
end
