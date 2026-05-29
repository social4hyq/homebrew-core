class MultiGitter < Formula
  desc "Update multiple repositories in with one command"
  homepage "https://github.com/lindell/multi-gitter"
  url "https://github.com/lindell/multi-gitter/archive/refs/tags/v0.63.1.tar.gz"
  sha256 "44114005fd83484a9a3f066aff58cc5d75607a6af14796eeb3c90ab45a70c211"
  license "Apache-2.0"
  head "https://github.com/lindell/multi-gitter.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6c60b268506144bf83646bff2b41ecbcd5c0cb29058f4c27d7c8c285c5608017"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"multi-gitter", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/multi-gitter version")

    output = shell_output("#{bin}/multi-gitter status 2>&1", 1)
    assert_match "Error: no organization, user, repo, repo-search or code-search set", output
  end
end
