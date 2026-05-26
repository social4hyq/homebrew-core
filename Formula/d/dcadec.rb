class Dcadec < Formula
  desc "DTS Coherent Acoustics decoder with support for HD extensions"
  homepage "https://github.com/foo86/dcadec"
  url "https://github.com/foo86/dcadec.git",
      tag:      "v0.2.0",
      revision: "0e074384c9569e921f8facfe3863912cdb400596"
  license "LGPL-2.1-or-later"
  head "https://github.com/foo86/dcadec.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "c5606372852d658e0193239f0fd13c9402426ffaf2d688754071aeffa9d5f079"
  end

  # Ref https://github.com/foo86/dcadec/commit/b93deed1a231dd6dd7e39b9fe7d2abe05aa00158
  deprecate! date: "2024-06-30", because: :deprecated_upstream
  disable! date: "2025-07-02", because: :deprecated_upstream

  def install
    system "make", "all"
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    resource "homebrew-testdata" do
      url "https://github.com/foo86/dcadec-samples/raw/fa7dcf8c98c6d/xll_71_24_96_768.dtshd"
      sha256 "d2911b34183f7379359cf914ee93228796894e0b0f0055e6ee5baefa4fd6a923"
    end

    resource("homebrew-testdata").stage do
      system bin/"dcadec", resource("homebrew-testdata").cached_download
    end
  end
end
