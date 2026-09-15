class Zookeeper < Formula
  desc "Centralized server for distributed coordination of services"
  homepage "https://zookeeper.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=zookeeper/zookeeper-3.9.6/apache-zookeeper-3.9.6.tar.gz"
  mirror "https://archive.apache.org/dist/zookeeper/zookeeper-3.9.6/apache-zookeeper-3.9.6.tar.gz"
  sha256 "9277edd177f795c68b3a92cb411a79076b12ad3184fbf900c0d7cec9a0a52e0a"
  license "Apache-2.0"
  head "https://gitbox.apache.org/repos/asf/zookeeper.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cc6d83d2ae9252ea0be294c35f3bdaed3206541181476cdfd0ce1af3270d091d"
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "cppunit" => :build
  depends_on "libtool" => :build
  depends_on "maven" => :build
  depends_on "pkgconf" => :build

  depends_on "openjdk"
  depends_on "openssl@3"

  def default_zk_env
    <<~EOS
      [ -z "$ZOOCFGDIR" ] && export ZOOCFGDIR="#{pkgetc}"
    EOS
  end

  def install
    system "mvn", "install", "-Pfull-build", "-DskipTests"

    system "tar", "-xf", "zookeeper-assembly/target/apache-zookeeper-#{version}-bin.tar.gz"
    binpfx = "apache-zookeeper-#{version}-bin"
    libexec.install binpfx+"/bin", binpfx+"/lib", "zookeeper-contrib"
    rm(Dir["build-bin/bin/*.cmd"])

    system "tar", "-xf", "zookeeper-assembly/target/apache-zookeeper-#{version}-lib.tar.gz"
    libpfx = "apache-zookeeper-#{version}-lib"
    include.install Dir[libpfx+"/usr/include/*"]
    lib.install Dir[libpfx+"/usr/lib/*"]

    (var/"log/zookeeper").mkpath
    (var/"run/zookeeper/data").mkpath

    Pathname.glob("#{libexec}/bin/*.sh") do |path|
      next if path == libexec/"bin/zkEnv.sh"

      script_name = path.basename
      bin_name    = path.basename ".sh"
      (bin+bin_name).write <<~EOS
        #!/bin/bash
        export JAVA_HOME="${JAVA_HOME:-#{Formula["openjdk"].opt_prefix}}"
        . "#{pkgetc}/defaults"
        exec "#{libexec}/bin/#{script_name}" "$@"
      EOS
    end

    (buildpath/"defaults").write(default_zk_env)
    cp "conf/logback.xml", "logback.xml"
    cp "conf/zoo_sample.cfg", "conf/zoo.cfg"
    inreplace "conf/zoo.cfg",
              /^dataDir=.*/, "dataDir=#{var}/run/zookeeper/data"
    pkgetc.install "conf/zoo.cfg", "defaults", "logback.xml"
    (pkgshare/"examples").install "conf/logback.xml", "conf/zoo_sample.cfg"
  end

  service do
    run [opt_bin/"zkServer", "start-foreground"]
    environment_variables SERVER_JVMFLAGS: "-Dapple.awt.UIElement=true"
    keep_alive successful_exit: false
    working_dir var
  end

  test do
    output = shell_output("#{bin}/zkServer -h 2>&1")
    assert_match "Using config: #{pkgetc}/zoo.cfg", output
  end
end
