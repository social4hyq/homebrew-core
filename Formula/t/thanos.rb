class Thanos < Formula
  desc "Highly available Prometheus setup with long term storage capabilities"
  homepage "https://thanos.io"
  url "https://github.com/thanos-io/thanos/archive/refs/tags/v0.41.0.tar.gz"
  sha256 "7566a654e7ed07f0aed194c4c2fee1f60bddfda0bd8d7458ce735ce2e868ffc8"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d8f9b5d178b3990496a4b8e9cda55521728068efc12de6ce4675a237c41f1b3b"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/thanos"
  end

  test do
    (testpath/"bucket_config.yaml").write <<~YAML
      type: FILESYSTEM
      config:
        directory: #{testpath}
    YAML

    output = shell_output("#{bin}/thanos tools bucket inspect --objstore.config-file bucket_config.yaml")
    assert_match "| ULID |", output
  end
end
