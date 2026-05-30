class ParallelDiskUsage < Formula
  desc "Highly parallelized, blazing fast directory tree analyzer"
  homepage "https://github.com/KSXGitHub/parallel-disk-usage"
  url "https://github.com/KSXGitHub/parallel-disk-usage/archive/refs/tags/0.24.0.tar.gz"
  sha256 "3250ede56826cc268c8fb05db8ce345204ec79ce541cd339ffdad9747c2b853c"
  license "Apache-2.0"
  head "https://github.com/KSXGitHub/parallel-disk-usage.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "fbc246290f8e69b0c037a8c03dbfa80354465920ab029c52e83e9f35a9bfa7a6"
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args

    bash_completion.install "exports/completion.bash" => "pdu"
    fish_completion.install "exports/completion.fish" => "pdu.fish"
    zsh_completion.install "exports/completion.zsh" => "_pdu"
    man1.install "exports/pdu.1"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pdu --version")

    system bin/"pdu"

    (testpath/"test").write("test")
    system bin/"pdu", testpath/"test"
  end
end
