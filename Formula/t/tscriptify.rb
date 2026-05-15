class Tscriptify < Formula
  desc "Golang struct to TypeScript class/interface converter"
  homepage "https://github.com/tkrajina/typescriptify-golang-structs"
  url "https://github.com/tkrajina/typescriptify-golang-structs/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "0bc43bb0e4e70fb10402be448b58eae7babd19f69e9dcbf4ff77f8f62c1b8abc"
  license "Apache-2.0"
  head "https://github.com/tkrajina/typescriptify-golang-structs.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6bc3a6554bee7323f23734af18eb01b81746eb622e953e95ede4a1f1fc657b39"
  end

  depends_on "go" => [:build, :test]

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./tscriptify"
  end

  test do
    system "go", "mod", "init", "brewtest"
    system "go", "get", "github.com/tkrajina/typescriptify-golang-structs/typescriptify@v#{version}"

    (testpath/"test.go").write <<~GO
      package brewtest

      type Address struct {
        City    string  `json:"city"`
        Number  float64 `json:"number"`
        Country string  `json:"country,omitempty"`
      }
    GO
    (testpath/"expected.ts").write <<~TYPESCRIPT
      /* Do not change, this code is generated from Golang structs */


      export class Address {
          city: string;
          number: number;
          country?: string;

          constructor(source: any = {}) {
              if ('string' === typeof source) source = JSON.parse(source);
              this.city = source["city"];
              this.number = source["number"];
              this.country = source["country"];
          }
      }
    TYPESCRIPT

    system bin/"tscriptify", "-package=brewtest", "-target=output.ts", "Address"
    assert_equal (testpath/"expected.ts").read.strip, (testpath/"output.ts").read
  end
end
