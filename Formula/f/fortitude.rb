class Fortitude < Formula
  desc "Fortran linter"
  homepage "https://fortitude.readthedocs.io/en/stable/"
  url "https://github.com/PlasmaFAIR/fortitude/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "04018554aadd9b846c99b5ffc218fe483c353020daefb777af39a75724a6338e"
  license "MIT"
  head "https://github.com/PlasmaFAIR/fortitude.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8807ac2fce8f0b23e9f465b20d23fc82f67ba84101c79557f3598fdc7e0af861"
  end

  depends_on "rust" => :build

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    system "cargo", "install", *std_cargo_args(path: "crates/fortitude")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/fortitude --version")

    (testpath/"test.f90").write <<~FORTRAN
      PROGRAM hello
        WRITE(*,'(A)') 'Hello World!'
      ENDPROGRAM
    FORTRAN

    output = shell_output("#{bin}/fortitude check #{testpath}/test.f90 --output-format concise 2>&1", 1)
    assert_match "fortitude: 1 files scanned.\nNumber of errors: 5", output
  end
end
