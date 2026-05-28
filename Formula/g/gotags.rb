class Gotags < Formula
  desc "Tag generator for Go, compatible with ctags"
  homepage "https://github.com/jstemmer/gotags"
  url "https://github.com/jstemmer/gotags/archive/refs/tags/v1.4.1.tar.gz"
  sha256 "2df379527eaa7af568734bc4174febe7752eb5af1b6194da84cd098b7c873343"
  license "MIT"
  head "https://github.com/jstemmer/gotags.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "68abf4d19e5f267f9fb30a13f0483ace4df0ba7eaf98a061adbccb01db7f9fc6"
  end

  depends_on "go" => :build

  def install
    ENV["GO111MODULE"] = "auto"
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"test.go").write <<~GO
      package main

      type Foo struct {
          Bar int
      }
    GO

    assert_match(/^Bar.*test.go.*$/, shell_output("#{bin}/gotags #{testpath}/test.go"))
  end
end
