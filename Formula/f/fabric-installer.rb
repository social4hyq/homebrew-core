class FabricInstaller < Formula
  desc "Installer for Fabric for the vanilla launcher"
  homepage "https://fabricmc.net/"
  url "https://maven.fabricmc.net/net/fabricmc/fabric-installer/1.1.1/fabric-installer-1.1.1.jar"
  sha256 "2487a69dd6f9d9c2605265a7142d77c26ab62edc620e6bcf810d581d2ee31b79"
  license "Apache-2.0"

  # The first-party download page (https://fabricmc.net/use/) uses JavaScript
  # to create download links, so we check the related JSON data for versions.
  livecheck do
    url "https://meta.fabricmc.net/v2/versions/installer"
    strategy :json do |json|
      json.map do |release|
        next if release["stable"] != true

        release["version"]
      end
    end
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "e35c228084842ddd388a0f0ade7f4c24fb858ce2b4ae8332d3fc64957ede21db"
  end

  depends_on "openjdk"

  def install
    libexec.install "fabric-installer-#{version}.jar"
    bin.write_jar_script libexec/"fabric-installer-#{version}.jar", "fabric-installer"
  end

  test do
    system bin/"fabric-installer", "server"
    assert_path_exists testpath/"fabric-server-launch.jar"
  end
end
