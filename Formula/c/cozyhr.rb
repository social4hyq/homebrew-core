class Cozyhr < Formula
  desc "Cozy wrapper around Helm and Flux CD for local development"
  homepage "https://github.com/cozystack/cozyhr"
  url "https://github.com/cozystack/cozyhr/archive/refs/tags/v1.6.1.tar.gz"
  sha256 "2b93668c7c24ebdc0588ca15e7821de77879b883c263f2d295fba41fb9b1c05c"
  license "Apache-2.0"
  head "https://github.com/cozystack/cozyhr.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5897b29d1396edd7cbd902a15200ece4858d83323dd3eb14104e10971e0cf1ba"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=#{version}")
    generate_completions_from_executable(bin/"cozyhr", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/cozyhr --version")
    assert_match "try setting KUBERNETES_MASTER environment variable", shell_output("#{bin}/cozyhr list 2>&1", 1)
  end
end
