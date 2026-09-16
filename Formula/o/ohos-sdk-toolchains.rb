class OhosSdkToolchains < Formula
  desc "OpenHarmony SDK toolchains component (hdc, restool and signing tools)"
  homepage "https://gitcode.com/openharmony"
  url "https://cidownload.openharmony.cn/version/Master_Version/ohos-sdk-public_ohos/20260330_020501/version-Master_Version-ohos-sdk-public_ohos-20260330_020501-ohos-sdk-public_ohos.tar.gz"
  version "26.0.0.18"
  sha256 "191094c9efcc4c0a6874aadaec5a1bf8b16f09f60c8f34a828d4ab0007356248"
  license "Apache-2.0"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "206c907c2ec8a6c0b9d4c4d6ea70c3fa62298fa8bface11eda856479ba609ee9"
  end

  # This formula installs a single package of the official SDK, `ohos-sdk`
  # depends on all of them and stays the only formula exposing the SDK command
  # line tools. This keg is never linked: consume it through its `opt_prefix`.
  keg_only "it is a component of `ohos-sdk`"

  depends_on "unzip" => :build

  def install
    cd "ohos" do
      Dir.glob("toolchains-*.zip").each do |zip_file|
        system "unzip", "-q", zip_file
      end
    end

    # This formula packages one component of the SDK, so the content of the
    # `toolchains` directory lands at the root of the keg: the prefix of this
    # formula is the SDK `toolchains` directory.
    prefix.install (buildpath/"ohos/toolchains").children
  end

  test do
    assert_path_exists prefix/"hdc"
    assert_path_exists prefix/"ark_disasm"
    assert_path_exists prefix/"lib/binary-sign-tool"

    assert_match "RestoolV2", shell_output("#{prefix}/restool --version")
  end
end
