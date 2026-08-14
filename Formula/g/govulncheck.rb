class Govulncheck < Formula
  desc "Database client and tools for the Go vulnerability database"
  homepage "https://github.com/golang/vuln"
  url "https://github.com/golang/vuln/archive/refs/tags/v1.7.0.tar.gz"
  sha256 "4fb7f0204b7e039f550d8938b714c5218d870694895585e0e19b2c0c4700e4c7"
  license "BSD-3-Clause"
  head "https://github.com/golang/vuln.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "06f4b92e857621643da47f3140dc150c44bf64f17dde05b1764dcc9f6a7d9e97"
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
