class GitGet < Formula
  desc "Better way to clone, organize and manage multiple git repositories"
  homepage "https://github.com/grdl/git-get"
  url "https://github.com/grdl/git-get/archive/refs/tags/v0.6.1.tar.gz"
  sha256 "82a24231bffacc0a8eaf50d21892ac6160f5f616cafccd2381b8bc9845452ff4"
  license "MIT"
  head "https://github.com/grdl/git-get.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0cb2fb1f88362d08c86b7e14c59e684adf3e8a77bac6fc18debd1e8b9b03b90e"
  end

  depends_on "go" => :build
  depends_on "go-md2man" => :build

  def install
    ldflags = "-s -w -X git-get/pkg/cfg.version=#{version}"
    system "go", "build", *std_go_args(ldflags:, output: bin/"git-get"), "./cmd"
    bin.install_symlink "git-get" => "git-list"

    system "go-md2man", "-in=README.md", "-out=git-get.1"
    man1.install "git-get.1"
    man1.install_symlink "git-get.1" => "git-list.1"
  end

  test do
    clone_path = homepage.sub(%r{^https?://}, "")
    system bin/"git-get", homepage, "--root", "."
    assert_predicate testpath/clone_path, :directory?

    cd clone_path do
      remotes = shell_output("git remote --verbose")
      assert_match "origin", remotes
      assert_match "#{homepage} (fetch)", remotes
      assert_match "#{homepage} (push)", remotes
      refute_empty remotes
    end
  end
end
