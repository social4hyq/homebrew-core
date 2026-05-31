class Gerust < Formula
  desc "Project generator for Rust backend projects"
  homepage "https://gerust.rs/"
  url "https://github.com/mainmatter/gerust/archive/refs/tags/v0.0.6.tar.gz"
  sha256 "1036cc5461e91f775bf499575f2352cba8a91ac2c97d2b312bdc19601d300038"
  license "MIT"
  head "https://github.com/mainmatter/gerust.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9427466918cdfb7ddd8081cacf42327c8e498cc712e3b4d2037f1b1cc61f33e4"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@3"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix

    system "cargo", "install", *std_cargo_args
  end

  test do
    require "utils/linkage"

    assert_match version.to_s, shell_output("#{bin}/gerust --version")

    (testpath/"brewtest").mkpath
    output = shell_output("#{bin}/gerust brewtest --minimal 2>&1")
    assert_match "Could not generate project!", output

    [
      Formula["openssl@3"].opt_lib/shared_library("libssl"),
      Formula["openssl@3"].opt_lib/shared_library("libcrypto"),
    ].each do |library|
      assert Utils.binary_linked_to_library?(bin/"gerust", library),
             "No linkage with #{library.basename}! Cargo is likely using a vendored version."
    end
  end
end
