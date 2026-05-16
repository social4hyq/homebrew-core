class RsyncTimeBackup < Formula
  desc "Time Machine-style backup for the terminal using rsync"
  homepage "https://github.com/laurent22/rsync-time-backup"
  url "https://github.com/laurent22/rsync-time-backup/archive/refs/tags/v1.1.5.tar.gz"
  sha256 "567f42ddf2c365273252f15580bb64aa3b3a8abb4a375269aea9cf0278510657"
  license "MIT"
  head "https://github.com/laurent22/rsync-time-backup.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "55d23275f1f186ccb2ab21cd75bdd2ea2839079f7c3876ec06517c56eb96d0ef"
  end

  def install
    bin.install "rsync_tmbackup.sh"
  end

  test do
    output = shell_output("#{bin}/rsync_tmbackup.sh --rsync-get-flags")
    assert_match "--times --recursive", output
  end
end
