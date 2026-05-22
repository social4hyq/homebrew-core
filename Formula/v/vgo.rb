class Vgo < Formula
  desc "Project scaffolder for Go, written in Go"
  homepage "https://github.com/vg006/vgo"
  url "https://github.com/vg006/vgo/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "262ab18eb8e2f68031e17727c1c8b0e01e61c385dcd7addbd2c1ae86ecd312b4"
  license "MIT"
  head "https://github.com/vg006/vgo.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2672cc7ebaf88b05536d39bf3407ba1f1360a443f6f5712c634d1c53e168a5ae"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"vgo", shell_parameter_format: :cobra)
  end

  test do
    expected = if OS.mac?
      "Failed to build the vgo tool"
    else
      "┃ ✔ Built vgo\n┃ ✔ Installed vgo"
    end
    assert_match expected, shell_output("#{bin}/vgo build 2>&1")
  end
end
