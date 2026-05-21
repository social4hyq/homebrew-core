class JsonnetBundler < Formula
  desc "Package manager for Jsonnet"
  homepage "https://github.com/jsonnet-bundler/jsonnet-bundler"
  url "https://github.com/jsonnet-bundler/jsonnet-bundler.git",
      tag:      "v0.6.0",
      revision: "ddded59c7066658f3d5abc7fcfc6be2220c92cad"
  license "Apache-2.0"
  head "https://github.com/jsonnet-bundler/jsonnet-bundler.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "39a80def2d1c8361438ffd761c8f71a50c0ea7a6dfe5bad13c70c436a47765b3"
  end

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.Version=#{version}", output: bin/"jb"), "./cmd/jb"
  end

  test do
    assert_match "A jsonnet package manager", shell_output("#{bin}/jb 2>&1")

    system bin/"jb", "init"
    assert_path_exists testpath/"jsonnetfile.json"

    system bin/"jb", "install", "https://github.com/grafana/grafonnet-lib"
    assert_predicate testpath/"vendor", :directory?
    assert_path_exists testpath/"jsonnetfile.lock.json"
  end
end
