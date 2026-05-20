class Mp3cat < Formula
  desc "Reads and writes mp3 files"
  homepage "https://tomclegg.ca/mp3cat"
  url "https://github.com/tomclegg/mp3cat/archive/refs/tags/0.5.tar.gz"
  sha256 "b1ec915c09c7e1c0ff48f54844db273505bc0157163bed7b2940792dca8ff951"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "87c959abf300b40a835e01a4425e4583d615665bfb9c49f2243fb2f2f4c9b68f"
  end

  def install
    system "make"
    bin.install %w[mp3cat mp3log mp3log-conf mp3dirclean mp3http mp3stream-conf]
  end

  test do
    pipe_output("#{bin}/mp3cat -v --noclean - -", test_fixtures("test.mp3").to_s)
  end
end
