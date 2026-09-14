class OsvScanner < Formula
  desc "Vulnerability scanner which uses the OSV database"
  homepage "https://github.com/google/osv-scanner"
  url "https://github.com/google/osv-scanner/archive/refs/tags/v2.6.0.tar.gz"
  sha256 "848ead2e06aa6e6150cecc2d82b867da7636d241e50b88f0922511acdac00a00"
  license "Apache-2.0"
  head "https://github.com/google/osv-scanner.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "f1f3cd951ccfa3c1fc9625a85b2ca01c099d769b450586fe0bf8e9f802a14498"
  end

  depends_on "go" => [:build, :test]

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/osv-scanner"
  end

  test do
    (testpath/"go.mod").write <<~GOMOD
      module my-library

      require (
        github.com/BurntSushi/toml v1.0.0
      )
    GOMOD

    scan_output = shell_output("#{bin}/osv-scanner --lockfile #{testpath}/go.mod")
    assert_match "Scanned #{testpath}/go.mod file and found 1 package", scan_output
  end
end
