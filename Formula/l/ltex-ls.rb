class LtexLs < Formula
  desc "LSP for LanguageTool with support for Latex, Markdown and Others"
  homepage "https://valentjn.github.io/ltex/"
  url "https://github.com/valentjn/ltex-ls/archive/refs/tags/16.0.0.tar.gz"
  sha256 "0cd67495ee4695493fc2a0b37d14146325aa6b9f45d767d16c60abdefdd2dc1d"
  license "MPL-2.0"
  revision 1
  head "https://github.com/valentjn/ltex-ls.git", branch: "develop"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "b730448d319341815c3ba2ca19db72deb23d08cbcec69b7e2dc5e67a19585a1f"
  end

  depends_on "maven" => :build
  depends_on "python@3.14" => :build
  # Do not bump, 25+ is not working with an error: java.lang.IllegalArgumentException: 25
  depends_on "openjdk@21"

  def install
    # Fix build with `openjdk` 20.
    # Reported upstream at https://github.com/valentjn/ltex-ls/issues/244.
    inreplace "pom.xml", "<arg>-Werror</arg>", ""

    ENV.prepend_path "PATH", Formula["python@3.14"].opt_libexec/"bin"
    ENV["JAVA_HOME"] = Language::Java.java_home(Formula["openjdk@21"].version.major.to_s)
    ENV["TMPDIR"] = buildpath

    system "python3.14", "-u", "tools/createCompletionLists.py"

    system "mvn", "-B", "-e", "-DskipTests", "package"

    mkdir "build" do
      system "tar", "xzf", "../target/ltex-ls-#{version}.tar.gz", "-C", "."

      # remove Windows files
      rm Dir["ltex-ls-#{version}/bin/*.bat"]
      bin.install Dir["ltex-ls-#{version}/bin/*"]
      libexec.install Dir["ltex-ls-#{version}/*"]
    end

    # Fix run with `openjdk` 24.
    # Reported upstream at https://github.com/valentjn/ltex-ls/issues/322.
    envs = Language::Java.overridable_java_home_env("21").merge({
      "JAVA_OPTS" => "${JAVA_OPTS:--Djdk.xml.totalEntitySizeLimit=50000000}",
    })
    bin.env_script_all_files libexec/"bin", envs
  end

  test do
    (testpath/"test").write <<~EOS
      She say wrong.
    EOS

    (testpath/"expected").write <<~EOS
      #{testpath}/test:1:5: info: The pronoun 'She' is usually used with a third-person or a past tense verb. [HE_VERB_AGR]
      She say wrong.
          Use 'says'
          Use 'said'
    EOS

    got = shell_output("#{bin}/ltex-cli '#{testpath}/test'", 3)
    assert_equal (testpath/"expected").read, got
  end
end
