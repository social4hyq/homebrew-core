class CoreosCt < Formula
  desc "Convert a Container Linux Config into Ignition"
  homepage "https://flatcar-linux.org/docs/latest/provisioning/config-transpiler/"
  url "https://github.com/flatcar/container-linux-config-transpiler/archive/refs/tags/v0.9.4.tar.gz"
  sha256 "c173ced842a6d178000f9bf01b26e9a8c296b1256ab713834f18d3f0883c4263"
  license "Apache-2.0"
  head "https://github.com/flatcar/container-linux-config-transpiler.git", branch: "flatcar-master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "a73506f9ca1d6b1c0f06f71660760741224c951c1bbe2a978c0d830e5603275c"
  end

  depends_on "go" => :build

  conflicts_with "chart-testing", because: "both install `ct` binaries"

  def install
    system "make", "all", "VERSION=v#{version}"
    bin.install "./bin/ct"
  end

  test do
    (testpath/"input").write <<~EOS
      passwd:
        users:
          - name: core
            ssh_authorized_keys:
              - ssh-rsa mykey
    EOS
    output = shell_output("#{bin}/ct -pretty -in-file #{testpath}/input").lines.map(&:strip).join
    assert_match(/.*"sshAuthorizedKeys":\s*\["ssh-rsa mykey"\s*\].*/m, output.strip)
  end
end
