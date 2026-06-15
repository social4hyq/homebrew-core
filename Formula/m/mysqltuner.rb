class Mysqltuner < Formula
  desc "Increase performance and stability of a MySQL installation"
  homepage "https://mysqltuner.com/"
  url "https://github.com/jmrenouard/MySQLTuner-perl/archive/refs/tags/v2.8.45.tar.gz"
  sha256 "64e44a0eeb7caf37f87768e58c130b55962a56824d761c9040abe583dac2cbdb"
  license "GPL-3.0-or-later"
  head "https://github.com/jmrenouard/MySQLTuner-perl.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6ee1e03b00ae04701ceba734bda23a78c49b5c09cc8c20cbdc36ee500e7b1491"
  end

  def install
    bin.install "mysqltuner.pl" => "mysqltuner"
  end

  # mysqltuner analyzes your database configuration by connecting to a
  # mysql server. It is not really feasible to spawn a mysql server
  # just for a test case so we'll stick with a rudimentary test.
  test do
    system bin/"mysqltuner", "--help"
  end
end
