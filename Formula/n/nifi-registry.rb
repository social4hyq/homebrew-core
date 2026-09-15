class NifiRegistry < Formula
  desc "Centralized storage & management of NiFi/MiNiFi shared resources"
  homepage "https://nifi.apache.org/projects/registry"
  url "https://www.apache.org/dyn/closer.lua?path=/nifi/2.12.0/nifi-registry-2.12.0-bin.zip"
  mirror "https://archive.apache.org/dist/nifi/2.12.0/nifi-registry-2.12.0-bin.zip"
  sha256 "0107bf0054e0a73ec6ff2957c7f0c48aa854e5a7d349864fb24917588ead9d69"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "dafd08e599964a6d359d21cd175ad0a47b4432d61f5e7ce7209597e98070b505"
  end

  depends_on "openjdk"

  def install
    libexec.install Dir["*"]
    rm Dir[libexec/"bin/*.bat"]

    bin.install libexec/"bin/nifi-registry.sh" => "nifi-registry"
    bin.env_script_all_files libexec/"bin/",
                             Language::Java.overridable_java_home_env.merge(NIFI_REGISTRY_HOME: libexec)
  end

  test do
    output = shell_output("#{bin}/nifi-registry status")
    assert_match "Apache NiFi Registry is not running", output
  end
end
