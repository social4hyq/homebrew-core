class Gcviewer < Formula
  desc "Java garbage collection visualization tool"
  homepage "https://github.com/chewiebug/GCViewer"
  url "https://downloads.sourceforge.net/project/gcviewer/gcviewer-1.37.jar"
  sha256 "325a5f1a8f67588b6845c71eceb70c8b74c45930fd553ba2fc7b3b4118608e13"
  license "LGPL-2.1-or-later"
  revision 1

  livecheck do
    url :stable
    regex(%r{url=.*?/gcviewer[._-]v?(\d+(?:\.\d+)+)\.jar}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1ebd94a8e78f6ce1c3f67ee50329086f0d5098b12b893760ce513119c57b6220"
  end

  depends_on "openjdk"

  def install
    libexec.install Dir["*"]
    bin.write_jar_script libexec/"gcviewer-#{version}.jar", "gcviewer"
  end

  test do
    assert_path_exists libexec/"gcviewer-#{version}.jar"
  end
end
