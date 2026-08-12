class Snooze < Formula
  desc "Run a command at a particular time"
  homepage "https://github.com/leahneukirchen/snooze"
  url "https://github.com/leahneukirchen/snooze/archive/refs/tags/v0.6.tar.gz"
  sha256 "3a4a2f3f00d42e30647d9af79c8e417990ced6c3f0565474b1ca717938b1e2ab"
  license :public_domain

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "cfd29d3ff09edb1c237340563eac1e8c6003c5c153bdf241824b74b7cc9bb30d"
  end

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    assert_match "T00:00:00", shell_output("#{bin}/snooze -n")
  end
end
