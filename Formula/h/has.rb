class Has < Formula
  desc "Checks presence of various command-line tools and their versions on the path"
  homepage "https://github.com/kdabir/has"
  url "https://github.com/kdabir/has/archive/refs/tags/v1.5.2.tar.gz"
  sha256 "965629d00b9c41fab2a9c37b551e3d860df986d86cdebd9b845178db8f1c998e"
  license "MIT"
  head "https://github.com/kdabir/has.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fcf5e155c34b54c4d360264c8b8c3c7d33e4a28bc7ed59b0297b5f7781663fa8"
  end

  def install
    bin.install "has"
  end

  test do
    assert_match "git", shell_output("#{bin}/has git")
    assert_match version.to_s, shell_output("#{bin}/has --version")
  end
end
