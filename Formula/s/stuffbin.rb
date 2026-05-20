class Stuffbin < Formula
  desc "Compress and embed static files and assets into Go binaries"
  homepage "https://github.com/knadh/stuffbin"
  url "https://github.com/knadh/stuffbin/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "10de8bdec2997299beaff857cd5a4c74b3951c9e4dab97b68f7b97af8d564ac3"
  license "MIT"
  head "https://github.com/knadh/stuffbin.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ba5912fa30ba4c4d2f562d833193855eae7d4d55e6d5622e7301759d654ccd73"
  end

  depends_on "go" => [:build, :test]

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./stuffbin"
  end

  test do
    mkdir "brewtest" do
      system "go", "mod", "init", "brewtest"
      system "go", "get", "github.com/knadh/stuffbin"

      (testpath/"brewtest/foo.txt").write "brewfoo"
      (testpath/"brewtest/main.go").write <<~GO
        package main

        import (
          "log"
          "os"

          "github.com/knadh/stuffbin"
        )

        func main() {
          path, _ := os.Executable()
          fs, _ := stuffbin.UnStuff(path)
          f, _ := fs.Get("foo.txt")
          log.Println("foo.txt =", string(f.ReadBytes()))
        }
      GO

      system "go", "build", "."
      output = shell_output("#{bin}/stuffbin -a stuff -in brewtest -out brewtest2 foo.txt")
      assert_match "stuffing complete.", output
      assert_match "foo.txt = brewfoo", shell_output("#{testpath}/brewtest/brewtest2 2>&1")

      output = shell_output("#{bin}/stuffbin -a id -in brewtest2")
      assert_match "brewtest2: stuffbin", output
      assert_match "/foo.txt", output
    end
  end
end
