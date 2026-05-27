class Spark < Formula
  desc "Sparklines for the shell"
  homepage "https://zachholman.com/spark/"
  url "https://github.com/holman/spark/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "a81c1bc538ce8e011f62264fe6f33d28042ff431b510a6359040dc77403ebab6"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fcc00276710dbde68414fdb3bcd2d1f8ae229ab2077e6b0581c34bd3758516a6"
  end

  def install
    bin.install "spark"
  end

  test do
    system bin/"spark"
  end
end
