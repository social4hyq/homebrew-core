class AwsRotateKey < Formula
  desc "Easily rotate your AWS access key"
  homepage "https://github.com/stefansundin/aws-rotate-key"
  url "https://github.com/stefansundin/aws-rotate-key/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "91568ad7aeb849454ac066c44303e2b97e158dc094a90af43c8c9b3dc5cc4ed7"
  license "MIT"
  head "https://github.com/stefansundin/aws-rotate-key.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "36a939f5616498518602cd7f61a4d9cc385db22fbfe0e4bc0fd6d93eb7bcf726"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w")
  end

  test do
    (testpath/"credentials").write <<~EOF
      [default]
      aws_access_key_id=AKIA123
      aws_secret_access_key=abc
    EOF
    output = shell_output("AWS_SHARED_CREDENTIALS_FILE=#{testpath}/credentials #{bin}/aws-rotate-key -y 2>&1", 1)
    assert_match "InvalidClientTokenId: The security token included in the request is invalid", output
  end
end
