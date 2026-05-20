class GoBlueprint < Formula
  desc "CLI to streamline Go project setup with standardized structure"
  homepage "https://docs.go-blueprint.dev/"
  url "https://github.com/Melkeydev/go-blueprint/archive/refs/tags/v0.10.11.tar.gz"
  sha256 "4c5a8d75738fe73266b6e9d051829d7810c3787d52ab4c939c19ca92c9493004"
  license "MIT"
  head "https://github.com/Melkeydev/go-blueprint.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "badde145500000a45ebdc9f4cd3ab80103cd33210cb995fb994d11b789ffd3c3"
  end

  depends_on "go"

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X github.com/melkeydev/go-blueprint/cmd.GoBlueprintVersion=#{version}")

    generate_completions_from_executable(bin/"go-blueprint", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/go-blueprint version")

    module_name = "brew.sh/test"
    cmd = [bin/"go-blueprint", "create", "--name", module_name,
           "--framework", "gin", "--driver", "sqlite", "--git", "skip"]
    if OS.mac?
      system(*cmd)
    else
      require "pty"
      pid = PTY.spawn(*cmd).last
      Process.wait(pid)
    end

    test_project = testpath/"test"
    assert_path_exists test_project/"cmd/api/main.go"
    assert_match "module #{module_name}", (test_project/"go.mod").read
  end
end
