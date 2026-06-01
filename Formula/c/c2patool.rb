class C2patool < Formula
  desc "CLI for working with C2PA manifests and media assets"
  homepage "https://contentauthenticity.org"
  url "https://github.com/contentauth/c2pa-rs/archive/refs/tags/c2patool-v0.26.61.tar.gz"
  sha256 "4023c5ae77902e6de6bac9e8dbf31dbdd8b622e130a9d7830be84dd82b798def"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/contentauth/c2pa-rs.git", branch: "main"

  livecheck do
    url :stable
    regex(/^c2patool[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "bf4900c93b2ba37bdb5adccfc0a80946c87490819b0a22638e0515eb76243014"
  end

  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "openssl@4"

  def install
    ENV["OPENSSL_DIR"] = Formula["openssl@4"].opt_prefix
    system "cargo", "install", *std_cargo_args(path: "cli")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/c2patool -V").strip

    (testpath/"test.json").write <<~JSON
      {
        "assertions": [
          {
            "label": "com.example.test",
            "data": {
              "my_key": "my_value"
            }
          }
        ]
      }
    JSON

    system bin/"c2patool", test_fixtures("test.png"), "-m", "test.json", "-o", "signed.png", "--force"

    output = shell_output("#{bin}/c2patool signed.png")
    assert_match "\"issuer\": \"C2PA Test Signing Cert\"", output
  end
end
