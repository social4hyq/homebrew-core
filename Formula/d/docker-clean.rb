class DockerClean < Formula
  desc "Clean Docker containers, images, networks, and volumes"
  homepage "https://github.com/ZZROTDesign/docker-clean"
  url "https://github.com/ZZROTDesign/docker-clean/archive/refs/tags/v2.0.4.tar.gz"
  sha256 "4b636fd7391358b60c05b65ba7e89d27eaf8dd56cc516f3c786b59cadac52740"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6cedd3ffbcc44fbce861f71fe66b46d4fe5d72c6cf5083a80bc6847a280d7f0d"
  end

  def install
    bin.install "docker-clean"
  end

  test do
    system bin/"docker-clean", "--help"
  end
end
