class Cloudprober < Formula
  desc "Active monitoring software to detect failures before your customers do"
  homepage "https://cloudprober.org"
  url "https://github.com/cloudprober/cloudprober/archive/refs/tags/v0.14.3.tar.gz"
  sha256 "13c013f9c80abc011646f4c3e90bc9e68ed3d94ce6b2794934545d980060d5c5"
  license "Apache-2.0"
  head "https://github.com/cloudprober/cloudprober.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a4817a73da376f2cc71b97703d448e50d2fd3c529d2710a3ec0a9f8a519c1e22"
  end

  depends_on "go" => :build

  def install
    system "make", "cloudprober", "VERSION=v#{version}"
    bin.install "cloudprober"
  end

  test do
    io = IO.popen("#{bin}/cloudprober --logtostderr", err: [:child, :out])
    io.any? do |line|
      line.include?("Initialized status surfacer")
    end
  end
end
