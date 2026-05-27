class Jump < Formula
  desc "Helps you navigate your file system faster by learning your habits"
  homepage "https://github.com/gsamokovarov/jump"
  url "https://github.com/gsamokovarov/jump/archive/refs/tags/v0.67.0.tar.gz"
  sha256 "b54bc4d1173be7ad5e4866f3b76f02c59506cc66b05fafe4aa3854cad1d2d531"
  license "MIT"
  head "https://github.com/gsamokovarov/jump.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3b3e037487dceca85c6b953e6f10f045dcf4009ad3f25c23f16530b6797e362f"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")

    generate_completions_from_executable(bin/"jump", "shell")
    man1.install "man/jump.1"
    man1.install "man/j.1"
  end

  test do
    (testpath/"test_dir").mkpath
    ENV["JUMP_HOME"] = testpath.to_s
    system bin/"jump", "chdir", testpath/"test_dir"

    assert_equal (testpath/"test_dir").to_s, shell_output("#{bin}/jump cd tdir").chomp
  end
end
