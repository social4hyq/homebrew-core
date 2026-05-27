class Uru < Formula
  desc "Use multiple rubies on multiple platforms"
  homepage "https://bitbucket.org/jonforums/uru"
  url "https://bitbucket.org/jonforums/uru/get/v0.8.5.tar.gz"
  sha256 "47148454f4c4d5522641ac40aec552a9390a2edc1a0cd306c5d16924f0be7e34"
  license "BSD-3-Clause"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "0989668569e7d6e80333fd63f80ae50aa49084f59459a4a2fa4e6ee7808b2527"
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["GO111MODULE"] = "auto"
    (buildpath/"src/bitbucket.org/jonforums/uru").install Dir["*"]
    system "go", "build", "-ldflags", "-s", "bitbucket.org/jonforums/uru/cmd/uru"
    bin.install "uru" => "uru_rt"
  end

  def caveats
    <<~EOS
      Append to ~/.profile on Ubuntu, or to ~/.zshrc on Zsh
      $ echo 'eval "$(uru_rt admin install)"' >> ~/.bash_profile
    EOS
  end

  test do
    system bin/"uru_rt"
  end
end
