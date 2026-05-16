class GdriveDownloader < Formula
  desc "Download a gdrive folder or file easily, shell ftw"
  homepage "https://github.com/Akianonymus/gdrive-downloader"
  url "https://github.com/Akianonymus/gdrive-downloader/archive/refs/tags/v2.0.tar.gz"
  sha256 "0c9cccf7c10b02b31fd1e8b40b8c68b6d2cce34bc1534c7732024a21d637d273"
  license "Unlicense"
  head "https://github.com/Akianonymus/gdrive-downloader.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ae21900ed20113ac328a5c69337c3f99531e6517015deb84f997f91825093794"
  end

  on_macos do
    depends_on "bash"
  end

  def install
    bin.install "release/gdl"
  end

  test do
    assert_match "No valid arguments provided, use -h/--help flag to see usage.", shell_output("#{bin}/gdl")
  end
end
