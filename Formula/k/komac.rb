class Komac < Formula
  desc "Community Manifest Creator for Windows Package Manager (WinGet)"
  homepage "https://github.com/russellbanks/Komac"
  url "https://github.com/russellbanks/Komac/archive/refs/tags/v2.16.0.tar.gz"
  sha256 "a88eb12956091e2e5bd9b15184a4efc953c037346fe66f81d2553c08b9e81da4"
  license "GPL-3.0-or-later"
  head "https://github.com/russellbanks/Komac.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "adf24a78c8f1120cbcd26e38843016f9eb98ac19f9f5082b507dbe822bbfb4a7"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build

  on_linux do
    depends_on "openssl@3"
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args
    generate_completions_from_executable(bin/"komac", "complete")
  end

  test do
    resource "testdata" do
      url "https://github.com/russellbanks/Komac/releases/download/v2.13.0/komac-setup-2.13.0-x86_64-pc-windows-msvc.exe"
      sha256 "32c460e6d29903396f92f7b44dee1f9ac57f15d5c882d306e9af19fc7828842c"
    end

    resource("testdata").stage do
      assert_match "DisplayVersion: 2.13.0",
shell_output("#{bin}/komac analyse komac-setup-2.13.0-x86_64-pc-windows-msvc.exe")
    end
  end
end
