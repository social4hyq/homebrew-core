class Topicctl < Formula
  desc "Declarative Kafka topic management"
  homepage "https://github.com/segmentio/topicctl"
  url "https://github.com/segmentio/topicctl/archive/refs/tags/v2.0.2.tar.gz"
  sha256 "fb97094222529c018917a0ac29cfd139b6991a168634eb067f7eb4b26b8424b5"
  license "MIT"
  head "https://github.com/segmentio/topicctl.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ab6c7e2a13e3cf5a28dad408b64c207d0444e87df3bced3ac1b0a62f3be9ae5f"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.Version=#{version}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/topicctl"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/topicctl --version")

    (testpath/"cluster.yaml").write <<~YAML
      meta:
        name: test-cluster
        environment: test-env
        region: test-region

      spec:
        bootstrapAddrs:
          - bootstrap-addr:9092
        zkAddrs:
          - zk-addr:2181
        zkPrefix: /test-cluster-id
        zkLockPath: /topicctl/locks
    YAML

    (testpath/"topics").mkpath
    (testpath/"topics/topic-test.yaml").write <<~YAML
      meta:
        name: topic-test
        cluster: test-cluster
        environment: test-env
        region: test-region

      spec:
        partitions: 9
        replicationFactor: 2
        retentionMinutes: 100
        placement:
          strategy: in-rack
        settings:
          cleanup.policy: compact
    YAML

    system bin/"topicctl", "check", "--validate-only", testpath/"topics/topic-test.yaml"
  end
end
