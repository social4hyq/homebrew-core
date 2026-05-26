class KitchenSync < Formula
  desc "Fast efficiently sync database without dumping & reloading"
  homepage "https://github.com/willbryant/kitchen_sync"
  url "https://github.com/willbryant/kitchen_sync/archive/refs/tags/v2.21.tar.gz"
  sha256 "0a2c25001069c90135a91b1cc70c1b9096c3c6e127f6a14f1b45cdbb0c209f09"
  license "MIT"
  head "https://github.com/willbryant/kitchen_sync.git", branch: "main"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "638272e9256c110b01090a7077990f6190278c62fe1317cbabaa1c1c3ebb2872"
  end

  depends_on "cmake" => :build
  depends_on "libpq"
  depends_on "mariadb-connector-c"

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DMySQL_INCLUDE_DIR=#{Formula["mariadb-connector-c"].opt_include}/mariadb",
                    "-DMySQL_LIBRARY_DIR=#{Formula["mariadb-connector-c"].opt_lib}",
                    "-DPostgreSQL_INCLUDE_DIR=#{Formula["libpq"].opt_include}",
                    "-DPostgreSQL_LIBRARY_DIR=#{Formula["libpq"].opt_lib}",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    output = shell_output("#{bin}/ks --from mysql://b/ --to mysql://d/ 2>&1", 1)

    assert_match "Unknown server host", output
    assert_match "Kitchen Syncing failed.", output
  end
end
