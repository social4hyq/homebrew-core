class Gokart < Formula
  desc "Static code analysis for securing Go code"
  homepage "https://github.com/praetorian-inc/gokart"
  url "https://github.com/praetorian-inc/gokart/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "81bf1e26531117de4da9b160ede80aa8f6c4d4984cc1d7dea398083b8e232eb7"
  license "Apache-2.0"
  head "https://github.com/praetorian-inc/gokart.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "596e556228d901f5ed0f05166abd6d909fc1ed50cd546196f6f10e29fc97a789"
  end

  deprecate! date: "2024-06-20", because: :repo_archived
  disable! date: "2025-06-21", because: :repo_archived

  depends_on "go" => [:build, :test]

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    mkdir "brewtest" do
      system "go", "mod", "init", "brewtest"
      (testpath/"brewtest/main.go").write <<~GO
        package main

        func main() {}
      GO
    end

    assert_match "GoKart found 0 potentially vulnerable functions",
      shell_output("#{bin}/gokart scan brewtest")

    assert_match version.to_s, shell_output("#{bin}/gokart version")
  end
end
