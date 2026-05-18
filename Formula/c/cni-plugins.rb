class CniPlugins < Formula
  desc "Container Network Interface plugins"
  homepage "https://www.cni.dev"
  url "https://github.com/containernetworking/plugins/archive/refs/tags/v1.9.1.tar.gz"
  sha256 "34bd82d47e981940751619c9cc44c095bb90bfcaf8d71865cbb822c37690a764"
  license "Apache-2.0"
  head "https://github.com/containernetworking/plugins.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "555a305b9af50d681398ed946135364e121bef3278f7b5e448348dc8c7d51eb1"
  end

  keg_only "plugin binaries are not intended to be under the $PATH"

  depends_on "go" => :build
  depends_on :linux

  def install
    buildpath.glob("plugins/{meta,main,ipam}/*").each do |plugin_path|
      basename = plugin_path.basename
      next if basename.to_s == "windows"

      system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/basename), plugin_path
    end
  end

  test do
    # Inspect supported CNI spec versions.
    ENV["CNI_COMMAND"] = "VERSION"
    output = JSON.parse shell_output("#{opt_bin}/bridge")
    assert_includes output["supportedVersions"], "1.1.0"
  end
end
