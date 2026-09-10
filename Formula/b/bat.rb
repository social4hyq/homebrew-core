class Bat < Formula
  desc "Clone of cat(1) with syntax highlighting and Git integration"
  homepage "https://github.com/sharkdp/bat"
  url "https://github.com/sharkdp/bat/archive/refs/tags/v0.26.1.tar.gz"
  sha256 "4474de87e084953eefc1120cf905a79f72bbbf85091e30cf37c9214eafcaa9c9"
  license any_of: ["Apache-2.0", "MIT"]
  revision 1
  compatibility_version 1
  head "https://github.com/sharkdp/bat.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2910db5804229507999607541de0e46408cae53f08065e61fd2446238a100e00"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "libgit2"
  depends_on "oniguruma"

  def install
    ENV["LIBGIT2_NO_VENDOR"] = "1"
    ENV["RUSTONIG_DYNAMIC_LIBONIG"] = "1"
    ENV["RUSTONIG_SYSTEM_LIBONIG"] = "1"

    system "cargo", "install", *std_cargo_args

    assets = buildpath.glob("target/release/build/bat-*/out/assets").first
    man1.install assets/"manual/bat.1"
    generate_completions_from_executable(bin/"bat", "--completion")
  end

  test do
    require "utils/linkage"

    pdf = test_fixtures("test.pdf")
    output = shell_output("#{bin}/bat #{pdf} --color=never")
    assert_match "Homebrew test", output

    [
      Formula["libgit2"].opt_lib/shared_library("libgit2"),
      Formula["oniguruma"].opt_lib/shared_library("libonig"),
    ].each do |library|
      assert Utils.binary_linked_to_library?(bin/"bat", library),
             "No linkage with #{library.basename}! Cargo is likely using a vendored version."
    end
  end
end
