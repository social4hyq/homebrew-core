class Podlet < Formula
  desc "Generate podman quadlet files from a podman command or compose file"
  homepage "https://github.com/containers/podlet"
  url "https://github.com/containers/podlet/archive/refs/tags/v0.3.2.tar.gz"
  sha256 "2dee85888e0f4ad1d8d7f6c7579d00faa69bb8dbcb4708706ef8db92e41f9bef"
  license "MPL-2.0"
  head "https://github.com/containers/podlet.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5bd183b6c091086b5b961433eb1fdaf4aecefeb2b8dca240ae4cdfe2cb6a243e"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    expected_output = <<~EOS
      # FileName=hello
      [Container]
      Image=quay.io/podman/hello
    EOS

    assert_equal expected_output, shell_output("#{bin}/podlet podman run quay.io/podman/hello")
  end
end
