class Headson < Formula
  desc "Head/tail for structured data"
  homepage "https://docs.rs/headson/latest/headson/"
  url "https://github.com/kantord/headson/archive/refs/tags/headson-v0.17.1.tar.gz"
  sha256 "7c04dbe3d94c8e828d453cfe93b68f0dbd25a72ce3735fc43d71e3e0ea2b9b32"
  license "MIT"
  head "https://github.com/kantord/headson.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1c595abcba84b9a249adb2cd72c7f7eb82d0afa206cf83dca5665c65e752b6e6"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"hson", "--completions")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hson --version")

    (testpath/"test.json").write '{"a":1,"b":[2,3]}'
    assert_match '"a":1', shell_output("#{bin}/hson --compact #{testpath}/test.json")
  end
end
