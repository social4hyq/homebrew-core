class Cdb < Formula
  desc "Create and read constant databases"
  homepage "https://cdb.cr.yp.to/"
  url "https://cdb.cr.yp.to/cdb-20251021.tar.gz"
  sha256 "8e531d6390bcd7c9a4cbd16fed36326eee78e8b0e5c0783a8158a6a79437e3dd"
  # https://cdb.cr.yp.to/license.html
  license any_of: [
    :public_domain, # LicenseRef-PD-hp - https://cr.yp.to/spdx.html
    "CC0-1.0",
    "0BSD",
    "MIT-0",
    "MIT",
  ]

  livecheck do
    url "https://cdb.cr.yp.to/download.html"
    regex(/href=.*?cdb[._-]v?(\d{8})\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "1377819882d17ba62ccf08c93fe516f52dc30c7edfe8cf1ac676eb2ae49a7c6b"
  end

  def install
    inreplace "conf-home", "/usr/local", prefix
    system "make", "setup"

    man1.install Dir["doc/man/*.1"]
    man3.install Dir["doc/man/*.3"]
    prefix.install_metafiles "doc"
    rm "README.md" # install doc/readme.md instead
  end

  test do
    record = "+4,8:test->homebrew\n\n"
    pipe_output("#{bin}/cdbmake db dbtmp", record, 0)
    assert_path_exists testpath/"db"
    assert_equal record, pipe_output("#{bin}/cdbdump", (testpath/"db").binread, 0)
  end
end
