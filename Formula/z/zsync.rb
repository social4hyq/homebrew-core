class Zsync < Formula
  desc "File transfer program"
  homepage "https://zsync.moria.org.uk/"
  url "https://zsync.moria.org.uk/download/zsync-0.8.0.tar.gz"
  sha256 "58b02f27e14326b62b7fdd6ed431a3e243b1c5a3ea9e3c1678e136dbf00c238d"
  license "Artistic-2.0"
  head "https://github.com/cph6/zsync.git", branch: "master"

  livecheck do
    url "https://zsync.moria.org.uk/downloads"
    regex(/href=.*?zsync[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "36d290525fbe34cba717e372cec3f22d2ee6907729a5acdc9d519443de1ee169"
  end

  depends_on "go" => :build

  def install
    (buildpath/"cmd").each_child(false) do |cmd|
      system "go", "build", *std_go_args(output: bin/cmd), "./cmd/#{cmd}"
      man1.install "man/#{cmd}.1"
    end
  end

  test do
    touch testpath/"foo"
    system bin/"zsyncmake", "foo"
    sha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    assert_match "File-Hash: SHA-256:#{sha256}", (testpath/"foo.zsync").read
  end
end
