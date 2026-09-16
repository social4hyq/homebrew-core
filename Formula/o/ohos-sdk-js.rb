class OhosSdkJs < Formula
  desc "OpenHarmony SDK js component (declarations and build tools)"
  homepage "https://gitcode.com/openharmony"
  url "https://cidownload.openharmony.cn/version/Master_Version/ohos-sdk-public_ohos/20260330_020501/version-Master_Version-ohos-sdk-public_ohos-20260330_020501-ohos-sdk-public_ohos.tar.gz"
  version "26.0.0.18"
  sha256 "191094c9efcc4c0a6874aadaec5a1bf8b16f09f60c8f34a828d4ab0007356248"
  license "Apache-2.0"

  # This formula installs a single package of the official SDK, `ohos-sdk`
  # depends on all of them and stays the only formula exposing the SDK command
  # line tools. This keg is never linked: consume it through its `opt_prefix`.
  keg_only "it is a component of `ohos-sdk`"

  depends_on "unzip" => :build

  def install
    cd "ohos" do
      Dir.glob("js-*.zip").each do |zip_file|
        system "unzip", "-q", zip_file
      end
    end

    # This formula packages one component of the SDK, so the content of the
    # `js` directory lands at the root of the keg: the prefix of this formula
    # is the SDK `js` directory.
    prefix.install (buildpath/"ohos/js").children
  end

  test do
    assert_path_exists prefix/"api"
    assert_path_exists prefix/"build-tools/ace-loader/index.js"
  end
end
