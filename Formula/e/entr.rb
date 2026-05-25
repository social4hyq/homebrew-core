class Entr < Formula
  desc "Run arbitrary commands when files change"
  homepage "https://eradman.com/entrproject/"
  url "https://eradman.com/entrproject/code/entr-5.8.tar.gz"
  sha256 "dc9a2bdc556b2be900c1d8cdf432de26492de5af3ffade000d4bfd97f3122bfb"
  license "ISC"
  head "https://github.com/eradman/entr.git", branch: "master"

  livecheck do
    url "https://eradman.com/entrproject/code/"
    regex(/href=.*?entr[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a6faeeeebc83e688c45f8d7cff81c6c74a4293bed844ea5f8f6b06bbb42ee35e"
  end

  def install
    ENV["PREFIX"] = prefix
    ENV["MANPREFIX"] = man
    system "./configure", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    touch testpath/"test.1"
    fork do
      sleep 2
      touch testpath/"test.2"
    end

    assert_equal "New File", pipe_output("#{bin}/entr -n -p -d echo 'New File'", testpath.to_s).strip
  end
end
