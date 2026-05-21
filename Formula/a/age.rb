class Age < Formula
  desc "Simple, modern, secure file encryption"
  homepage "https://github.com/FiloSottile/age"
  url "https://github.com/FiloSottile/age/archive/refs/tags/v1.3.1.tar.gz"
  sha256 "396007bc0bc53de253391493bda1252757ba63af1a19db86cfb60a35cb9d290a"
  license "BSD-3-Clause"
  head "https://github.com/FiloSottile/age.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e7225f9d6257409bfb6905d4a9f0cfb1cb37c9f4d61d91adc94f31311ecc3c5d"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=v#{version}"
    (buildpath/"cmd").each_child(false) do |cmd|
      system "go", "build", *std_go_args(ldflags:, output: bin/cmd), "./cmd/#{cmd}"
    end

    man1.install "doc/age.1"
    man1.install "doc/age-keygen.1"
  end

  test do
    system bin/"age-keygen", "-o", "key.txt"
    pipe_output("#{bin}/age -e -i key.txt -o test.age", "test", 0)
    assert_equal "test", shell_output("#{bin}/age -d -i key.txt test.age")
  end
end
