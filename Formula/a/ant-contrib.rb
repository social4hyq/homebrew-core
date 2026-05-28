class AntContrib < Formula
  desc "Collection of tasks for Apache Ant"
  homepage "https://ant-contrib.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/ant-contrib/ant-contrib/1.0b3/ant-contrib-1.0b3-bin.tar.gz"
  sha256 "6e58c2ee65e1f4df031796d512427ea213a92ae40c5fc0b38d8ac82701f42a3c"
  license "Apache-1.1"

  livecheck do
    url :stable
    regex(%r{url=.*?/ant-contrib[._-]v?(\d+(?:\.\d+)+(?:[a-z]\d+)?)-bin\.t}i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "6f0060a27d47c1d0f1be1a5154f14ed3364715f2326768dacced2614483a54df"
  end

  depends_on "ant"

  def install
    (share/"ant").install "ant-contrib-1.0b3.jar"
    share.install "docs"
  end

  test do
    (testpath/"build.xml").write <<~XML
      <project name="HomebrewTest" default="init" basedir=".">
        <taskdef resource="net/sf/antcontrib/antcontrib.properties"/>
        <target name="init">
          <if>
            <equals arg1="BREW" arg2="BREW" />
            <then>
              <echo message="Test passes!"/>
            </then>
          </if>
        </target>
      </project>
    XML
    system Formula["ant"].opt_bin/"ant"
  end
end
