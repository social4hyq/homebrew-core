class Packetbeat < Formula
  desc "Lightweight Shipper for Network Data"
  homepage "https://www.elastic.co/products/beats/packetbeat"
  url "https://github.com/elastic/beats.git",
      tag:      "v9.5.3",
      revision: "05460763bc6067b3a4708bc80219092eba134988"
  license "Apache-2.0"
  revision 1
  head "https://github.com/elastic/beats.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1fe22c046083afdc8baf2cf5977d0e50fa5a06cbacc12478ef840d09209c4de0"
  end

  depends_on "go" => :build
  depends_on "mage" => :build

  uses_from_macos "libpcap"

  def install
    ENV["CGO_ENABLED"] = "1" if OS.linux? && Hardware::CPU.arm?

    # remove non open source files
    rm_r("x-pack")

    # remove requirements.txt files so that build fails if venv is used.
    # currently only needed by docs/tests
    rm buildpath.glob("**/requirements.txt")

    cd "packetbeat" do
      # don't build docs because we aren't installing them and allows avoiding venv
      inreplace "magefile.go", ", includeList, fieldDocs)", ", includeList)"

      system "mage", "-v", "build"
      system "mage", "-v", "update"

      inreplace "packetbeat.yml", "packetbeat.interfaces.device: any", "packetbeat.interfaces.device: en0"

      pkgetc.install Dir["packetbeat.*"], "fields.yml"
      (libexec/"bin").install "packetbeat"
      prefix.install "_meta/kibana"
    end

    (bin/"packetbeat").write <<~SH
      #!/bin/sh
      exec #{libexec}/bin/packetbeat \
        --path.config #{etc}/packetbeat \
        --path.data #{var}/lib/packetbeat \
        --path.home #{prefix} \
        --path.logs #{var}/log/packetbeat \
        "$@"
    SH

    chmod 0555, bin/"packetbeat" # generate_completions_from_executable fails otherwise
    generate_completions_from_executable(bin/"packetbeat", "completion", shells: [:bash, :zsh])
  end

  service do
    run opt_bin/"packetbeat"
  end

  test do
    eth = if OS.mac?
      "en"
    else
      "eth"
    end
    assert_match "0: #{eth}0", shell_output("#{bin}/packetbeat devices")
    assert_match version.to_s, shell_output("#{bin}/packetbeat version")
  end
end
