class Fisher < Formula
  desc "Plugin manager for the Fish shell"
  homepage "https://github.com/jorgebucaran/fisher"
  url "https://github.com/jorgebucaran/fisher/archive/refs/tags/4.4.8.tar.gz"
  sha256 "6e1b9cdc8a49918b817f87e15bebf5e8af749f856fb10808cdb9a889f77f1eae"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c6ffce94118fb3f5f8b284944606c934148bb367950bfd6f4bdd040cba8a9728"
  end

  depends_on "fish"

  def install
    fish_function.install "functions/fisher.fish"
    fish_completion.install "completions/fisher.fish"
  end

  test do
    system "#{Formula["fish"].bin}/fish", "-c", "fisher install jethrokuan/z"
    assert_equal File.read(testpath/".config/fish/fish_plugins"), "jethrokuan/z\n"
  end
end
