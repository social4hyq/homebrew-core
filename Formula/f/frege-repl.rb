class FregeRepl < Formula
  desc "REPL (read-eval-print loop) for Frege"
  homepage "https://github.com/Frege/frege-repl"
  url "https://github.com/Frege/frege-repl/releases/download/1.4-SNAPSHOT/frege-repl-1.4-SNAPSHOT.zip"
  version "1.4-SNAPSHOT"
  sha256 "2ca5f13bc5efaf8515381e8cdf99b4d4017264a462a30366a873cb54cc4f4640"
  license "BSD-3-Clause"
  revision 3

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2983cf8dd83338c2eb933102768e01584b75de0c6a61b6a152d914cacfb50adb"
  end

  # Last release on 2015-10-18, last commit on 2019-02-22.
  deprecate! date: "2026-05-22", because: :unmaintained
  disable! date: "2027-05-22", because: :unmaintained

  # TODO: Switch to `openjdk` on next release.
  depends_on "openjdk@17"

  def install
    rm(Dir["bin/*.bat"])
    libexec.install "bin", "lib"
    (bin/"frege-repl").write_env_script libexec/"bin/frege-repl", JAVA_HOME: Formula["openjdk@17"].opt_prefix
  end

  test do
    assert_match "65536", pipe_output(bin/"frege-repl", "println $ 64*1024\n:quit\n")
  end
end
