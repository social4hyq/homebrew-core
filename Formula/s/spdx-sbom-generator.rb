class SpdxSbomGenerator < Formula
  desc "Support CI generation of SBOMs via golang tooling"
  homepage "https://github.com/opensbom-generator/spdx-sbom-generator"
  url "https://github.com/opensbom-generator/spdx-sbom-generator/archive/refs/tags/v0.0.15.tar.gz"
  sha256 "3811d652de0f27d3bfa7c025aa6815805ef347a35b46f9e2a5093cc6b26f7b08"
  license any_of: ["Apache-2.0", "CC-BY-4.0"]

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "857def5d94ddd4bd8a24cbd41fd9f8470dfbf1c17f93036e2e69f609dda4e614"
  end

  deprecate! date: "2025-02-13", because: :repo_archived
  disable! date: "2026-02-13", because: :repo_archived

  depends_on "go" => [:build, :test]

  def install
    target = if OS.linux?
      inreplace "Makefile", "GOARCH=amd64", "GOARCH=arm64" if Hardware::CPU.arm?
      "build"
    elsif Hardware::CPU.arm?
      "build-mac-arm64"
    else
      "build-mac"
    end

    system "make", target

    prefix.install "bin"
  end

  test do
    system "go", "mod", "init", "example.com/tester"

    assert_equal "panic: runtime error: index out of range [0] with length 0",
                 shell_output("#{bin}/spdx-sbom-generator 2>&1", 2).split("\n")[4]
  end
end
