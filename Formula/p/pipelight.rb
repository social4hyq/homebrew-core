class Pipelight < Formula
  desc "Self-hosted, lightweight CI/CD pipelines for small projects via CLI"
  homepage "https://pipelight.dev"
  url "https://github.com/pipelight/pipelight/archive/refs/tags/v0.10.0.tar.gz"
  sha256 "8d3862757e5e91c19c9a8528a6e98a2f86c824a4529d52c320ebc7eee0135d43"
  license "GPL-2.0-only"
  head "https://github.com/pipelight/pipelight.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "81e49f4d52d3df8348dc556a6bf198cdcf56e4187c51d06e6f535b1874081cab"
  end

  depends_on "rust" => :build

  def install
    # upstream pr ref, https://github.com/pipelight/pipelight/pull/33
    system "cargo", "update", "-p", "libc"

    inreplace "cli/Cargo.toml", "version = \"0.0.0\"", "version = \"#{version}\"" if build.stable?

    system "cargo", "install", *std_cargo_args(path: "pipelight")

    bash_completion.install "autocompletion/pipelight.bash" => "pipelight"
    fish_completion.install "autocompletion/pipelight.fish"
    zsh_completion.install "autocompletion/_pipelight"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pipelight --version")

    # /opt/homebrew/Cellar/pipelight/0.10.0/bin/pipelight init --template yaml
    system bin/"pipelight", "init", "--template", "yaml"
    assert_equal <<~YAML, (testpath/"pipelight.yaml").read
      pipelines:
        - name: example
          steps:
            - name: first
              commands:
                - ls
                - pwd
            - name: second
              commands:
                - ls
                - pwd
    YAML

    assert_match "example", shell_output("#{bin}/pipelight ls")

    system bin/"pipelight", "run", "example"
  end
end
