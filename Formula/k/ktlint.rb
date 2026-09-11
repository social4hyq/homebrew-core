class Ktlint < Formula
  desc "Anti-bikeshedding Kotlin linter with built-in formatter"
  homepage "https://ktlint.github.io/"
  url "https://github.com/pinterest/ktlint/releases/download/2.0.0-ALPHA-4/ktlint-2.0.0-ALPHA-4.zip"
  version "2.0.0-ALPHA-4"
  sha256 "c84a64d424451392e939bf018fcbec7da7949fa734b613d828953a4140a926cc"
  license "MIT"
  revision 1

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "ae711bedf79f53e53d0c30f339de0f63e5c21e3b37d8ee7dcb5db35c7a7e5e6d"
  end

  depends_on "openjdk"

  def install
    libexec.install "bin/ktlint"
    (libexec/"ktlint").chmod 0755
    (bin/"ktlint").write_env_script libexec/"ktlint", Language::Java.java_home_env
  end

  test do
    (testpath/"Main.kt").write <<~KOTLIN
      fun main( )
    KOTLIN

    (testpath/"Out.kt").write <<~KOTLIN
      fun main()
    KOTLIN

    system bin/"ktlint", "-F", "Main.kt"
    assert_equal shell_output("cat Main.kt"), shell_output("cat Out.kt")
  end
end
