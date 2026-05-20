class YouGet < Formula
  include Language::Python::Virtualenv

  desc "Dumb downloader that scrapes the web"
  homepage "https://you-get.org/"
  url "https://files.pythonhosted.org/packages/2d/85/f4a22b842bc0e0f57dc56ae54266dbc451547cee90bae9480131100ad92a/you_get-0.4.1743.tar.gz"
  sha256 "cbc1250d577246ec9d422cef113882844c80d8729f32d3183a5fa76648a20741"
  license "MIT"
  head "https://github.com/soimort/you-get.git", branch: "develop"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "686adb0ca5fa2d3efc27aec5608a087226df6766d1c8e79b0e80950c54581629"
  end

  depends_on "python@3.14"
  depends_on "rtmpdump"

  resource "dukpy" do
    url "https://files.pythonhosted.org/packages/dd/fe/8cef39f269aed53e940c238bf9ceb3ca0f80d7f5be6df2c00a84d87ac5d8/dukpy-0.5.0.tar.gz"
    sha256 "079fe2d65ac5e24df56806c6b4e1a26f92bb7f13dc764f4fb230a6746744c1ad"
  end

  def install
    virtualenv_install_with_resources
    bash_completion.install "contrib/completion/you-get-completion.bash" => "you-get"
    fish_completion.install "contrib/completion/you-get.fish"
    zsh_completion.install "contrib/completion/_you-get"
  end

  def caveats
    "To use post-processing options, run `brew install ffmpeg` or `brew install libav`."
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/you-get --version 2>&1")
    assert_match "82 bytes", shell_output("#{bin}/you-get --info https://imgur.com/ZTZ6Xy1")
  end
end
