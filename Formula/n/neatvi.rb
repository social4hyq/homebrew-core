class Neatvi < Formula
  desc "Clone of ex/vi for editing bidirectional utf-8 text"
  homepage "https://repo.or.cz/neatvi.git"
  url "https://repo.or.cz/neatvi.git",
      tag:      "19",
      revision: "45dafe8592090c0dfd8b29e33e6aafd0600ae19e"
  license "ISC"
  head "https://repo.or.cz/neatvi.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1354d38a543e60078618436774a86d3b662829d48953c716e8150375c0289aa2"
  end

  def install
    system "make"
    bin.install "vi" => "neatvi"
  end

  test do
    pipe_output(bin/"neatvi", ":q\n")
  end
end
