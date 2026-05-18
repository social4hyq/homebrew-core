class RakeCompletion < Formula
  desc "Bash completion for Rake"
  homepage "https://github.com/mernen/completion-ruby"
  url "https://github.com/mernen/completion-ruby/archive/refs/tags/v1.0.3.tar.gz"
  sha256 "cbcd002bba2a43730cff54f5386565917913d9dec16dcd89345fbe298fe4316b"
  license "MIT"
  head "https://github.com/mernen/completion-ruby.git", branch: "main"

  livecheck do
    formula "ruby-completion"
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "2287ecc3254c1b28a998e14a43aedcd374761eab032d8077c344e02fbe76e75b"
  end

  def install
    bash_completion.install "completion-rake" => "rake"
  end

  test do
    assert_match "-F __rake",
      shell_output("bash -c 'source #{bash_completion}/rake && complete -p rake'")
  end
end
