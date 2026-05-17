class Wskdeploy < Formula
  desc "Apache OpenWhisk project deployment utility"
  homepage "https://openwhisk.apache.org/"
  url "https://github.com/apache/openwhisk-wskdeploy/archive/refs/tags/1.2.0.tar.gz"
  sha256 "bffe6f6ef2167189fc38893943a391aaf7327e9e6b8d27be1cc1c26535c06e86"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "d552e6483259c9b791db62d3b7e5dcd2a6c11731254d01e57bd8e8cbdd65084f"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wskdeploy version")

    (testpath/"manifest.yaml").write <<~YAML
      packages:
        hello_world_package:
          version: 1.0
          license: Apache-2.0
    YAML

    system bin/"wskdeploy", "-v",
                            "--apihost", "openwhisk.ng.bluemix.net",
                            "--preview",
                            "-m", testpath/"manifest.yaml",
                            "-u", "abcd"
  end
end
