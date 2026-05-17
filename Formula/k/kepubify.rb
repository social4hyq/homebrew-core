class Kepubify < Formula
  desc "Convert ebooks from epub to kepub"
  homepage "https://pgaskin.net/kepubify/"
  url "https://github.com/pgaskin/kepubify/archive/refs/tags/v4.0.4.tar.gz"
  sha256 "a3bf118a8e871b989358cb598746efd6ff4e304cba02fd2960fe35404a586ed5"
  license "MIT"
  head "https://github.com/pgaskin/kepubify.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "709d6dbec01202ea0901e6f837844932db90863442b09308ae351f5b37c9b848"
  end

  depends_on "go" => :build

  def install
    %w[
      kepubify
      covergen
      seriesmeta
    ].each do |p|
      system "go", "build", *std_go_args(output: bin/p, ldflags: "-s -w -X main.version=#{version}"), "./cmd/#{p}"
    end
  end

  test do
    pdf = test_fixtures("test.pdf")
    output = shell_output("#{bin}/kepubify #{pdf} 2>&1", 1)
    assert_match "Error: invalid extension", output

    system bin/"kepubify", test_fixtures("test.epub")
    assert_path_exists testpath/"test_converted.kepub.epub"
  end
end
