class FormatUdf < Formula
  desc "Bash script to format a block device to UDF"
  homepage "https://github.com/JElchison/format-udf"
  url "https://github.com/JElchison/format-udf/archive/refs/tags/1.8.0.tar.gz"
  sha256 "52854097db9044d729fbd7cff012f4b554df01c15225ee17ec159c71da174c8d"
  license "GPL-2.0-or-later"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "16a69fbd6ead0de4b3f1e576a1b54ea2d4d1b2e3de218e91bca63c8515823c29"
  end

  def install
    bin.install "format-udf.sh" => "format-udf"
  end

  test do
    system bin/"format-udf", "-h"
  end
end
