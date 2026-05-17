class Uptoc < Formula
  desc "Convenient static file deployment tool that supports multiple platforms"
  homepage "https://github.com/bonaysoft/uptoc"
  url "https://github.com/bonaysoft/uptoc.git",
      tag:      "v1.4.3",
      revision: "30266b490379c816fc08ca3670fd96808214b24c"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "87772bc3bbedd62a608f80661665362c19013834973218b60ac6e7a6fc23e5cd"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.release=#{version} -X main.commit=#{Utils.git_head} -X main.repo=#{stable.url}"
    system "go", "build", *std_go_args(ldflags:), "./cmd"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/uptoc -v 2>&1")
    assert_match "uptoc config", shell_output("#{bin}/uptoc ./abc 2>&1", 1)
  end
end
