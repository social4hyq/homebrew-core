class Govulncheck < Formula
  desc "Database client and tools for the Go vulnerability database"
  homepage "https://github.com/golang/vuln"
  url "https://github.com/golang/vuln/archive/refs/tags/v1.4.0.tar.gz"
  sha256 "c2628a3fe43c2a0e75f3962ba7b72e8c1e35da59365db6ed63ed2870c549d466"
  license "BSD-3-Clause"
  head "https://github.com/golang/vuln.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b77416b15f036e7882ec9ce44e80e632274fa4b5fc4c32db295caad441660868"
  end

  depends_on "go" => [:build, :test]

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/govulncheck"
  end

  test do
    mkdir "brewtest" do
      system "go", "mod", "init", "brewtest"
      (testpath/"brewtest/main.go").write <<~GO
        package main

        func main() {}
      GO

      output = shell_output("#{bin}/govulncheck ./...")
      assert_match "No vulnerabilities found.", output
    end
  end
end
