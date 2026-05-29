class Goclone < Formula
  desc "Website Cloner"
  homepage "https://github.com/goclone-dev/goclone"
  url "https://github.com/goclone-dev/goclone/archive/refs/tags/v1.2.2.tar.gz"
  sha256 "1e005a045b3d2f5d4d0a7154f4552e537900c170256b668cc73aeac204d9defa"
  license "MIT"
  head "https://github.com/goclone-dev/goclone.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5108c9409a6546bd678b92e5af457ea95d1673f76f3cd3c31966e17ed499b890"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X sigs.k8s.io/release-utils/version.gitVersion=#{version}
      -X sigs.k8s.io/release-utils/version.gitCommit=#{tap.user}
      -X sigs.k8s.io/release-utils/version.buildDate=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/goclone"

    generate_completions_from_executable(bin/"goclone", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/goclone version")

    system bin/"goclone", "https://example.com"
    assert_path_exists testpath/"example.com"
  end
end
