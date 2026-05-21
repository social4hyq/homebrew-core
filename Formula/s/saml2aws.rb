class Saml2aws < Formula
  desc "Login and retrieve AWS temporary credentials using a SAML IDP"
  homepage "https://github.com/Versent/saml2aws"
  url "https://github.com/Versent/saml2aws/archive/refs/tags/v2.36.19.tar.gz"
  sha256 "208ec9e1f2e8c7e1770990825bc5e56c65cd86e8362e1a3e6fa1ef5ecc7bbc91"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "15a3ac50f75f07c143749f9cbd59faac517f06fd6e119d1764fa4d58085adf37"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/saml2aws"

    generate_completions_from_executable(bin/"saml2aws", shell_parameter_format: "--completion-script-",
                                                         shells:                 [:bash, :zsh])
  end

  test do
    assert_match "error building login details: Failed to validate account.: URL empty in idp account",
      shell_output("#{bin}/saml2aws script 2>&1", 1)

    assert_match version.to_s, shell_output("#{bin}/saml2aws --version 2>&1")
  end
end
