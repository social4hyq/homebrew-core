class Zsync < Formula
  desc "File transfer program"
  homepage "https://zsync.moria.org.uk/"
  url "https://zsync.moria.org.uk/download/zsync-0.7.1.tar.gz"
  sha256 "f521437761d9d19b5ca351f7736f28543cfb8a37391bbdc5b49681403268ff89"
  license "Artistic-2.0"
  head "https://github.com/cph6/zsync.git", branch: "master"

  livecheck do
    url "https://zsync.moria.org.uk/downloads"
    regex(/href=.*?zsync[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ca138019142e5656ccdb92c5009d9f4eb266cbc518bc203ffab29d6a7001967d"
  end

  depends_on "go" => :build

  def install
    (buildpath/"cmd").each_child(false) do |cmd|
      system "go", "build", *std_go_args(ldflags: "-s -w", output: bin/cmd), "./cmd/#{cmd}"
      man1.install "man/#{cmd}.1"
    end
  end

  test do
    touch testpath/"foo"
    system bin/"zsyncmake", "foo"
    sha1 = "da39a3ee5e6b4b0d3255bfef95601890afd80709"
    assert_match "SHA-1: #{sha1}", (testpath/"foo.zsync").read
  end
end
