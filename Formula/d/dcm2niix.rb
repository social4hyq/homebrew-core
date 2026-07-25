class Dcm2niix < Formula
  desc "DICOM to NIfTI converter"
  homepage "https://www.nitrc.org/plugins/mwiki/index.php/dcm2nii:MainPage"
  url "https://github.com/rordenlab/dcm2niix/archive/refs/tags/v1.0.20260724.tar.gz"
  sha256 "be6478b15aaf1e0c396df242e272a6a695966dc916672f519844ad1682b59e59"
  license "BSD-3-Clause"
  version_scheme 1
  head "https://github.com/rordenlab/dcm2niix.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "07a1b1dee02fae39a956d51f6cc5278be0ccdfaa23d42169bf3771fdfd42f915"
  end

  depends_on "cmake" => :build

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    resource "homebrew-sample.dcm" do
      url "https://raw.githubusercontent.com/dangom/sample-dicom/master/MR000000.dcm"
      sha256 "4efd3edd2f5eeec2f655865c7aed9bc552308eb2bc681f5dd311b480f26f3567"
    end

    resource("homebrew-sample.dcm").stage testpath
    system bin/"dcm2niix", "-f", "%d_%e", "-z", "n", "-b", "y", testpath
    assert_path_exists testpath/"localizer_1.nii"
    assert_path_exists testpath/"localizer_1.json"
  end
end
