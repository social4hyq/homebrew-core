class Lab < Formula
  desc "Git wrapper for GitLab"
  homepage "https://zaquestion.github.io/lab"
  url "https://github.com/zaquestion/lab/archive/refs/tags/v0.25.1.tar.gz"
  sha256 "f8cccdfbf1ca5a2c76f894321a961dfe0dc7a781d95baff5181eafd155707d79"
  license "CC0-1.0"
  head "https://github.com/zaquestion/lab.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1ebd3b44d7f8a861a7c675f0a5a3c3c62b4532cf755e7c522a617e337da473d4"
  end

  depends_on "go" => :build

  def install
    ldflags = "-X main.version=#{version} -s -w"
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"lab", shell_parameter_format: :cobra)
  end

  test do
    ENV["LAB_CORE_USER"] = "test_user"
    ENV["LAB_CORE_HOST"] = "https://gitlab.com"
    ENV["LAB_CORE_TOKEN"] = "dummy"

    ENV["GIT_AUTHOR_NAME"] = "test user"
    ENV["GIT_AUTHOR_EMAIL"] = "test@example.com"
    ENV["GIT_COMMITTER_NAME"] = "test user"
    ENV["GIT_COMMITTER_EMAIL"] = "test@example.com"

    output = shell_output("#{bin}/lab todo done 1 2>&1", 1)
    assert_match "POST https://gitlab.com/api/v4/todos/1/mark_as_done", output

    assert_match version.to_s, shell_output("#{bin}/lab version")
  end
end
