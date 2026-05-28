class KafkactlAwsPlugin < Formula
  desc "AWS Plugin for kafkactl"
  homepage "https://deviceinsight.github.io/kafkactl/"
  url "https://github.com/deviceinsight/kafkactl-plugins/archive/refs/tags/v1.3.1.tar.gz"
  sha256 "f7f5b961061c863131a9f84e8a6aa7d7273a16b1c3ad4fb86888edebda345eb1"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "9ccf56b26ec8cfcf6c0c8dc7518815f8f0d125a9baa1b7fff19bf0da8a6ef7cc"
  end

  depends_on "go" => :build
  depends_on "kafkactl"

  def install
    Dir.chdir("aws") do
      ldflags = %W[
        -s -w
        -X main.Version=v#{version}
        -X main.GitCommit=#{tap.user}
        -X main.BuildTime=#{time.iso8601}
      ]
      system "go", "build", *std_go_args(ldflags:)
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/kafkactl-aws-plugin 2>&1", 1)
    config_file = testpath/".kafkactl.yml"
    config_file.write <<~YAML
      contexts:
          default:
              brokers:
                  - unknown-cluster.kafka.eu-west-1.amazonaws.com:9098
              sasl:
                  enabled: true
                  mechanism: oauth
                  tokenprovider:
                      plugin: aws
              tls:
                  enabled: true
    YAML

    ENV["KAFKA_CTL_PLUGIN_PATHS"] = bin

    kafkactl = Formula["kafkactl"].bin/"kafkactl"
    output = shell_output("#{kafkactl} -C #{config_file} get topics -V 2>&1", 1)
    assert_match "kafkactl-aws-plugin: plugin initialized", output
  end
end
