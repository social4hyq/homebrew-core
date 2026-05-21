class Karn < Formula
  desc "Manage multiple Git identities"
  homepage "https://github.com/prydonius/karn"
  url "https://github.com/prydonius/karn/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "96f10ff263468b9f91244edf16d8ea548c9d281cba9b2597eaf5270f9e6127e3"
  license "MIT"
  head "https://github.com/prydonius/karn.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dcb76b7927728dd7b25daa039c720ec1b5d061601640a073179bea57a0a6a004"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/karn/karn.go"
  end

  test do
    (testpath/".karn.yml").write <<~YAML
      ---
      #{testpath}:
        name: Homebrew Test
        email: test@brew.sh
    YAML
    system "git", "init"
    system "git", "config", "--global", "user.name", "Test"
    system "git", "config", "--global", "user.email", "test@test.com"
    system "git", "config", "--global", "user.signingkey", "test"
    system bin/"karn", "update"
  end
end
