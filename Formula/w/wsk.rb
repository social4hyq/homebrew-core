class Wsk < Formula
  desc "OpenWhisk Command-Line Interface (CLI)"
  homepage "https://openwhisk.apache.org/"
  url "https://github.com/apache/openwhisk-cli/archive/refs/tags/1.2.0.tar.gz"
  sha256 "cafc57b2f2e29f204c00842541691038abcc4e639dd78485f9c042c93335f286"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "21d340aa647b3a69541ded0611ec74d0d23fb32e75a26f41cb29da5866578368"
  end

  depends_on "go" => :build
  depends_on "go-bindata" => :build

  def install
    system "go-bindata", "-pkg", "wski18n", "-o",
                          "wski18n/i18n_resources.go", "wski18n/resources"

    system "go", "build", *std_go_args

    generate_completions_from_executable(bin/"wsk", "sdk", "install", "bashauto", "--stdout",
                                         shells: [:bash], shell_parameter_format: :none)
  end

  test do
    system bin/"wsk", "property", "set", "--apihost", "https://127.0.0.1"
  end
end
