class Hebcal < Formula
  desc "Perpetual Jewish calendar for the command-line"
  homepage "https://github.com/hebcal/hebcal"
  url "https://github.com/hebcal/hebcal/archive/refs/tags/v5.15.0.tar.gz"
  sha256 "64f263e81de54b13b8b3d2bfae49bb1e7b71da6851ab71b038c06aac679b960d"
  license "GPL-2.0-or-later"
  head "https://github.com/hebcal/hebcal.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "adb51b369a3088ab91b0069833caf5aa90a1fbd078b82e7505dc47c725bdac1c"
  end

  depends_on "go" => :build

  def install
    # populate DEFAULT_CITY variable
    system "make", "dcity.go", "man"
    system "go", "build", *std_go_args(ldflags: "-s -w")
    man1.install "hebcal.1"
  end

  test do
    output = shell_output("#{bin}/hebcal 01 01 2020").chomp
    assert_equal output, "1/1/2020 4th of Tevet, 5780"
  end
end
