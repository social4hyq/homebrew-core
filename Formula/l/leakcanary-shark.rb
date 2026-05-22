class LeakcanaryShark < Formula
  desc "CLI Java memory leak explorer for LeakCanary"
  homepage "https://square.github.io/leakcanary/shark/"
  url "https://github.com/square/leakcanary/releases/download/v2.14/shark-cli-2.14.zip"
  sha256 "4a1022a4610fd6a4a1306b264f95985c4210e169e2bd4b0ad19bbdcc16d6beef"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "86ec5744fce46b56337c8b32ae765eb601d092c611d9e32890ab0ebaa5646e8e"
  end

  depends_on "openjdk"

  def install
    # Remove Windows scripts
    rm(Dir["bin/*.bat"])

    libexec.install Dir["*"]
    (bin/"shark-cli").write_env_script libexec/"bin/shark-cli", Language::Java.overridable_java_home_env
  end

  test do
    resource "homebrew-sample_hprof" do
      url "https://github.com/square/leakcanary/raw/v2.6/shark-android/src/test/resources/leak_asynctask_m.hprof"
      sha256 "7575158108b701e0f7233bc208decc243e173c75357bf0be9231a1dcb5b212ab"
    end

    testpath.install resource("homebrew-sample_hprof")
    assert_match "1 APPLICATION LEAKS",
                 shell_output("#{bin}/shark-cli --hprof ./leak_asynctask_m.hprof analyze").strip
  end
end
