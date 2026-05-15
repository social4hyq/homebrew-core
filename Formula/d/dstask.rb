class Dstask < Formula
  desc "Git-powered personal task tracker"
  homepage "https://github.com/naggie/dstask"
  url "https://github.com/naggie/dstask/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "afca526d049874e2609d91c0e5f186d614c684ec13b2fe517e00ec4eeb4f70da"
  license "MIT"
  head "https://github.com/naggie/dstask.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "88eac4d398e2273181230863bd292f69a3ca20d73ebd2cd68b815350ceba859c"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/naggie/dstask.GIT_COMMIT=#{tap.user}
      -X github.com/naggie/dstask.VERSION=#{version}
      -X github.com/naggie/dstask.BUILD_DATE=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:), "./cmd/dstask"
    system "go", "build", *std_go_args(ldflags:, output: bin/"dstask-import"), "./cmd/dstask-import"

    bash_completion.install "completions/bash.sh" => "dstask"
    fish_completion.install "completions/completions.fish" => "dstask.fish"
    zsh_completion.install "completions/zsh.sh" => "_dstask"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dstask version")

    mkdir ".dstask" do
      system "git", "init"
      system "git", "config", "user.name", "BrewTestBot"
      system "git", "config", "user.email", "BrewTestBot@test.com"
    end

    system bin/"dstask", "add", "Brew the brew"
    system bin/"dstask", "start", "1"
    assert_match "Brew the brew", shell_output("#{bin}/dstask show-active")
    system bin/"dstask", "done", "1"
  end
end
