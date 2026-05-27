class Samply < Formula
  desc "CLI sampling profiler"
  homepage "https://github.com/mstange/samply"
  url "https://github.com/mstange/samply/archive/refs/tags/samply-v0.13.1.tar.gz"
  sha256 "7002789471f8ef3a36f4d4db7be98f2847724e2b81a53c5e23d5cae022fb704b"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/mstange/samply.git", branch: "main"

  livecheck do
    url :stable
    regex(/^samply[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "85d3247be04f2e34b6bb87a4dfa619b688a09764ffa5d48765b61773e9ec65e4"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "samply")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/samply --version")

    test_perf_json = testpath/"test_perf.json"
    test_perf_json.write ""

    output = shell_output("#{bin}/samply import --no-open #{test_perf_json} 2>&1", 1)
    assert_match "Error importing perf.data file", output
  end
end
