class Linkerd < Formula
  desc "Command-line utility to interact with linkerd"
  homepage "https://linkerd.io"
  url "https://github.com/linkerd/linkerd2.git",
      tag:      "stable-2.14.10",
      revision: "1ea6b271718f90182bdf747490895784988e980e"
  license "Apache-2.0"
  head "https://github.com/linkerd/linkerd2.git", branch: "main"

  livecheck do
    url :stable
    regex(/^stable[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "3f7437df2498443cecbf6c526d785df492ef5cd243b06cf7bf13e24b3b16d464"
  end

  depends_on "go" => :build

  # upstream PR to bump go to v1.22, https://github.com/linkerd/linkerd2/pull/12114
  patch do
    url "https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/linkerd/stable-2.14.10.patch"
    sha256 "0d634f7ca5036e75435a10318f3e6a7d6a5c40ee0c21689a5f1814dbc5ba6911"
  end

  def install
    ENV["CI_FORCE_CLEAN"] = "1"

    system "bin/build-cli-bin"
    bin.install Dir["target/cli/*/linkerd"]

    generate_completions_from_executable(bin/"linkerd", "completion")
  end

  test do
    run_output = shell_output("#{bin}/linkerd 2>&1")
    assert_match "linkerd manages the Linkerd service mesh.", run_output

    version_output = shell_output("#{bin}/linkerd version --client 2>&1")
    assert_match "Client version: #{stable.specs[:tag]}", version_output

    system bin/"linkerd", "install", "--ignore-cluster"
  end
end
