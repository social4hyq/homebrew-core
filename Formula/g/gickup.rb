class Gickup < Formula
  desc "Backup all your repositories with Ease"
  homepage "https://cooperspencer.github.io/gickup-documentation/"
  url "https://github.com/cooperspencer/gickup/archive/refs/tags/v0.10.47.tar.gz"
  sha256 "ad7ef9de7c55e6f3822326120cb7a823a69bb966489c105bfc4e2ece673a412c"
  license "Apache-2.0"
  head "https://github.com/cooperspencer/gickup.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a99686db8dfc16660a89ab7c7bdcc8e2d8014904833c6dcf31984fd256abbcd9"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    (testpath/"conf.yml").write <<~YAML
      source:
        github:
          - token: brewtest-token
            user: Brew Test
            username: brewtest
            password: testpass
            ssh: true
    YAML

    output = shell_output("#{bin}/gickup --dryrun 2>&1", 1)
    assert_match "grabbing the repositories from Brew Test", output

    assert_match version.to_s, shell_output("#{bin}/gickup --version")
  end
end
