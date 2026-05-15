class Cig < Formula
  desc "CLI app for checking the state of your git repositories"
  homepage "https://github.com/stevenjack/cig"
  url "https://github.com/stevenjack/cig/archive/refs/tags/v0.1.5.tar.gz"
  sha256 "545a4a8894e73c4152e0dcf5515239709537e0192629dc56257fe7cfc995da24"
  license "MIT"
  head "https://github.com/stevenjack/cig.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "5d910b508aa1ab5d4e423d1988e28e42751e303df1f846d136d4235cb8719001"
  end

  depends_on "go" => :build

  # Patch to remove godep dependency.
  # Remove when the following PR is merged into release:
  # https://github.com/stevenjack/cig/pull/44
  patch do
    url "https://github.com/stevenjack/cig/compare/2d834ee..f0e78f0.patch?full_index"
    sha256 "3aa14ecfa057ec6aba08d6be3ea0015d9df550b4ede1c3d4eb76bdc441a59a47"
  end

  def install
    system "go", "build", *std_go_args
  end

  test do
    repo_path = "#{testpath}/test"
    system "git", "init", "--bare", repo_path
    (testpath/".cig.yaml").write <<~YAML
      test_project: #{repo_path}
    YAML
    system bin/"cig", "--cp=#{testpath}"
  end
end
