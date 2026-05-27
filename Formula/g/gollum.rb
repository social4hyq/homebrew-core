class Gollum < Formula
  desc "Go n:m message multiplexer"
  homepage "https://gollum.readthedocs.io/en/latest/"
  url "https://github.com/trivago/gollum/archive/refs/tags/0.6.0.tar.gz"
  sha256 "2d9e7539342ccf5dabb272bbba8223d279a256c0901e4a27d858488dd4343c49"
  license "Apache-2.0"
  head "https://github.com/trivago/gollum.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9d703b4dc105ba555847880e102c5e1df97f5b1271abe8d50b7f7e83174be085"
  end

  # no commits since july 1 2021, and cannot rebuild, https://github.com/trivago/gollum/issues/265
  deprecate! date: "2024-07-27", because: :unmaintained
  disable! date: "2025-07-27", because: :unmaintained

  depends_on "go" => :build

  def install
    # Work around https://github.com/trivago/gollum/issues/265
    mod = "github.com/CrowdStrike/go-metrics-prometheus"
    (buildpath/"vendor/#{mod}/go.mod").write <<~GOMOD
      module #{mod}
    GOMOD
    (buildpath/"go.work").write <<~EOS
      use .
      replace #{mod} => ./vendor/#{mod}
    EOS

    system "go", "build", "-mod=readonly", *std_go_args(ldflags: "-s -w -X gollum/core.versionString=#{version}")
  end

  test do
    (testpath/"test.conf").write <<~EOS
      "Profiler":
          Type: "consumer.Profiler"
          Runs: 100000
          Batches: 100
          Characters: "abcdefghijklmnopqrstuvwxyz .,!;:-_"
          Message: "%256s"
          Streams: "profile"
          KeepRunning: false
          ModulatorRoutines: 0

      "Benchmark":
          Type: "producer.Benchmark"
          Streams: "profile"
    EOS
    assert_match "Config OK.", shell_output("#{bin}/gollum -tc #{testpath}/test.conf")
  end
end
