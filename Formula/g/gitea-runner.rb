class GiteaRunner < Formula
  desc "Official Actions runner for Gitea"
  homepage "https://gitea.com/gitea/runner"
  url "https://gitea.com/gitea/runner/archive/v1.0.6.tar.gz"
  sha256 "68c6e65e7cc200921a64042bea695d333015888e0693d788c8c50bc8e7b97f83"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "80167b281ca37aca381bb28b53041a0ed32cde10eee397418c0fdc2313012db9"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X gitea.com/gitea/runner/internal/pkg/ver.version=v#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)
    generate_completions_from_executable(bin/"gitea-runner", shell_parameter_format: :cobra)

    (buildpath/"config.yaml").write Utils.safe_popen_read(bin/"gitea-runner", "generate-config")
    pkgetc.install "config.yaml"
    # Create working dir for services
    (var/"lib/gitea-runner").mkpath
  end

  def caveats
    "Config file: #{pkgetc}/config.yaml"
  end

  service do
    run [opt_bin/"gitea-runner", "daemon", "--config", etc/"gitea-runner/config.yaml"]
    keep_alive successful_exit: true
    environment_variables PATH: std_service_path_env

    working_dir var/"lib/gitea-runner"
    log_path var/"log/gitea-runner.log"
    error_log_path var/"log/gitea-runner.err"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gitea-runner --version")
    args = %w[
      --no-interactive
      --instance https://gitea.com
      --token INVALID_TOKEN
    ]
    output = shell_output("#{bin}/gitea-runner register #{args.join(" ")} 2>&1", 1)
    assert_match "Error: Failed to register runner", output
  end
end
