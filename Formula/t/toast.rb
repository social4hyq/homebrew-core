class Toast < Formula
  desc "Tool for running tasks in containers"
  homepage "https://github.com/stepchowfun/toast"
  url "https://github.com/stepchowfun/toast/archive/refs/tags/v0.48.0.tar.gz"
  sha256 "fc1812435641b40bd63cf9dd0fd33d2a7a24ffeda6302ef5d71b78cd4c1a606e"
  license "MIT"
  head "https://github.com/stepchowfun/toast.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "00112454d4cdf1b8d8ec8af7855926f2e7b0f11507a897bd464c6cb6fe769c36"
  end

  depends_on "rust" => :build

  conflicts_with "libgsm", because: "both install `toast` binaries"

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    (testpath/"toast.yml").write <<~YAML
      image: alpine
      tasks:
        homebrew_test:
          description: brewtest
          command: echo hello
    YAML

    assert_match "homebrew_test", shell_output("#{bin}/toast --list")
  end
end
