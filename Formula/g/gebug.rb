class Gebug < Formula
  desc "Debug Dockerized Go applications better"
  homepage "https://github.com/moshebe/gebug"
  url "https://github.com/moshebe/gebug/archive/refs/tags/v1.0.7.tar.gz"
  sha256 "3dac2b9b1f9a3d5fa8c19fceb7f77ea8ce003504239a2744bfc3c492b96a2e56"
  license "Apache-2.0"
  head "https://github.com/moshebe/gebug.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "afaf39c00c6806b313a2a591cff000376acf434cdb720ad2205a25ea87c8fbcb"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X github.com/moshebe/gebug/version.Version=#{version}
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"gebug", shell_parameter_format: :cobra)
  end

  test do
    ENV["DOCKER_HOST"] = "unix://#{testpath}/invalid.sock"

    (testpath/".gebug/docker-compose.yml").write("")
    (testpath/".gebug/Dockerfile").write("")

    assert_match "Failed to perform clean up", shell_output("#{bin}/gebug clean 2>&1", 1)
    assert_match version.to_s, shell_output("#{bin}/gebug version")
  end
end
