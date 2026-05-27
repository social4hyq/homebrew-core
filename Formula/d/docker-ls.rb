class DockerLs < Formula
  desc "Tools for browsing and manipulating docker registries"
  homepage "https://github.com/mayflower/docker-ls"
  url "https://github.com/mayflower/docker-ls.git",
      tag:      "v0.5.1",
      revision: "ae0856513066feff2ee6269efa5d665145709d2e"
  license "MIT"
  head "https://github.com/mayflower/docker-ls.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "aac0c7afa94890bc39a5c4de4c9f2527f908a2e002b30fbf8d7ce26794dd8a14"
  end

  deprecate! date: "2026-02-17", because: :repo_archived
  disable! date: "2027-02-17", because: :repo_archived

  depends_on "go" => :build

  def install
    system "go", "generate", "./lib"

    %w[docker-ls docker-rm].each do |name|
      system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/name), "./cli/#{name}"
    end
  end

  test do
    assert_match(/\Wlatest\W/m, pipe_output("#{bin}/docker-ls tags \
      -r https://index.docker.io -u '' -p '' \
      --progress-indicator=false library/busybox
    "))

    assert_match "401", pipe_output("#{bin}/docker-rm  \
      -r https://index.docker.io -u foo -p bar library/busybox:latest 2<&1
    ")
  end
end
