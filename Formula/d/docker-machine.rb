class DockerMachine < Formula
  desc "Create Docker hosts locally and on cloud providers"
  homepage "https://docs.gitlab.com/runner/executors/docker_machine.html"
  url "https://gitlab.com/gitlab-org/ci-cd/docker-machine/-/archive/v0.16.2-gitlab.52/docker-machine-v0.16.2-gitlab.52.tar.bz2"
  version "0.16.2-gitlab.52"
  sha256 "1d67717a83f53e409e1555642af44a1797e1f3d64cc80211599ede19665f9e79"
  license "Apache-2.0"
  compatibility_version 1
  head "https://gitlab.com/gitlab-org/ci-cd/docker-machine.git", branch: "main"

  bottle do
    rebuild 1
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c95f6c016eed7f3d0ac3f284e65e13eee6bb5e29c20f3f01f4b1cf9895d151da"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w"
    system "go", "build", *std_go_args(ldflags:), "./cmd/docker-machine"

    bash_completion.install Dir["contrib/completion/bash/*.bash"]
    zsh_completion.install "contrib/completion/zsh/_docker-machine"
  end

  service do
    run [opt_bin/"docker-machine", "start", "default"]
    environment_variables PATH: std_service_path_env
    run_type :immediate
    working_dir HOMEBREW_PREFIX
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/docker-machine --version")
  end
end
