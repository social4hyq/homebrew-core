class GphotosUploaderCli < Formula
  desc "Command-line tool to mass upload media folders to Google Photos"
  homepage "https://gphotosuploader.github.io/gphotos-uploader-cli/"
  url "https://github.com/gphotosuploader/gphotos-uploader-cli/archive/refs/tags/v5.1.0.tar.gz"
  sha256 "180ced2507d796b2305627097017aacd2b0206e1131e0b40da2a46563a823ec1"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "8f1312d1e0f2b82bb538d6fce2eb2226b252f87fc7058c0e34d2bae3e7ff5233"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/gphotosuploader/gphotos-uploader-cli/version.versionString=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)
    generate_completions_from_executable(bin/"gphotos-uploader-cli", shell_parameter_format: :cobra)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gphotos-uploader-cli version 2>&1")

    system bin/"gphotos-uploader-cli", "init", "--config", testpath
    assert_path_exists testpath/"config.hjson"
  end
end
