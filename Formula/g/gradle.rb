class Gradle < Formula
  desc "Open-source build automation tool based on the Groovy and Kotlin DSL"
  homepage "https://www.gradle.org/"
  url "https://services.gradle.org/distributions/gradle-9.7.1-all.zip"
  sha256 "92c1a136d76b5017732a66d2e0a648ebff00dd3687d8bff0d0047a1bd904fdf2"
  license "Apache-2.0"
  revision 1

  livecheck do
    url "https://gradle.org/releases/"
    regex(/href=.*?gradle[._-]v?(\d+(?:\.\d+)+)-all\.(?:zip|t)/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "baef71187620274b6a2c6feb7c9bc47accad77f9564ba92fecdfeb028d1d2387"
  end

  depends_on "gradle-completion"
  # https://github.com/gradle/gradle/blob/master/platforms/documentation/docs/src/docs/userguide/releases/compatibility.adoc
  depends_on "openjdk"

  def install
    rm(Dir["bin/*.bat"])
    libexec.install %w[bin lib src] # excluding 300MB+ of docs

    # Fix compatibility with reduced environment (e.g., BusyBox/ToyBox xargs).
    # Upstream Gradle uses nested single/double quotes in DEFAULT_JVM_OPTS,
    # which fails to strip internal quotes correctly during downstream `xargs -n1`
    # pipe execution on this system, leading to java.lang.ClassNotFoundException.
    # Flattening the nested quotes to standard double quotes safe-resolves this.
    inreplace libexec/"bin/gradle" do |s|
      s.gsub! "DEFAULT_JVM_OPTS='\"-Xmx64m\" \"-Xms64m\"'\" \\\"-javaagent:$APP_HOME/lib/agents/gradle-instrumentation-agent-#{version}.jar\\\"\"",
              "DEFAULT_JVM_OPTS=\"-Xmx64m -Xms64m -javaagent:$APP_HOME/lib/agents/gradle-instrumentation-agent-#{version}.jar\""
    end

    env = Language::Java.overridable_java_home_env
    (bin/"gradle").write_env_script libexec/"bin/gradle", env
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/gradle --version")

    (testpath/"settings.gradle").write ""
    (testpath/"build.gradle").write <<~GRADLE
      println "gradle works!"
    GRADLE
    gradle_output = shell_output("#{bin}/gradle build --no-daemon")
    assert_includes gradle_output, "gradle works!"
  end
end
