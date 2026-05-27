class Richgo < Formula
  desc "Enrich `go test` outputs with text decorations"
  homepage "https://github.com/kyoh86/richgo"
  url "https://github.com/kyoh86/richgo/archive/refs/tags/v0.3.12.tar.gz"
  sha256 "811db92c36818be053fa3950d40f8cca13912b8a4a9f54b82a63e2f112d2c4fe"
  license "MIT"
  head "https://github.com/kyoh86/richgo.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f23756676e0b2798cda27c07f43106bebb93fbb91e7178abe52c71012bd269ac"
  end

  depends_on "go" => [:build, :test]

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"go.mod").write <<~GOMOD
      module github.com/Homebrew/brew-test

      go 1.21
    GOMOD

    (testpath/"main.go").write <<~GO
      package main

      import "fmt"

      func Hello() string {
        return "Hello, gotestsum."
      }

      func main() {
        fmt.Println(Hello())
      }
    GO

    (testpath/"main_test.go").write <<~GO
      package main

      import "testing"

      func TestHello(t *testing.T) {
        got := Hello()
        want := "Hello, gotestsum."
        if got != want {
          t.Errorf("got %q, want %q", got, want)
        }
      }
    GO

    output = shell_output("#{bin}/richgo test ./...")

    expected = if OS.mac?
      "PASS | github.com/Homebrew/brew-test"
    else
      "ok  \tgithub.com/Homebrew/brew-test"
    end
    assert_match expected, output
  end
end
