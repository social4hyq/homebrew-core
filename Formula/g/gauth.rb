class Gauth < Formula
  desc "Google Authenticator in your terminal"
  homepage "https://github.com/pcarrier/gauth"
  url "https://github.com/pcarrier/gauth/archive/refs/tags/v1.5.0.tar.gz"
  sha256 "5c98287f5c209b9f02ec62ede4abd4117aa3ca738fbcb4153a6ec1e966f492a8"
  license "ISC"
  head "https://github.com/pcarrier/gauth.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c865fbb3350939927e7d022dfd4b414e21948e31437e60d61e244f0345c796b0"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    refute_empty pipe_output "#{bin}/gauth demo --add", "JBSWY3DPEHPK3PXP"
    assert_match(/demo(\s+\d{6}){3}/, shell_output(bin/"gauth"))
  end
end
