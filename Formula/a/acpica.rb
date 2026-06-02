class Acpica < Formula
  desc "OS-independent implementation of the ACPI specification"
  homepage "https://github.com/acpica/acpica"
  url "https://github.com/acpica/acpica/releases/download/20260408/acpica-unix2-20260408.tar.gz"
  sha256 "5fcef9f0d00ffaffaaa82aa49c5ea9687986e8a7bd60929e298cc99a6741ae24"
  license any_of: ["Intel-ACPI", "GPL-2.0-only", "BSD-3-Clause"]
  head "https://github.com/acpica/acpica.git", branch: "master"

  livecheck do
    url "https://www.intel.com/content/www/us/en/download/776303/acpi-component-architecture-downloads-unix-format-source-code-and-build-environment-with-an-intel-license.html"
    regex(/href=.*?acpica-unix[._-]v?(\d+(?:\.\d+)*)\.t/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "edfb519f92e42303f7ddda94bb5c2a118f465c1dc87082622c2aff4c484c96ae"
  end

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build
  uses_from_macos "m4" => :build

  def install
    # ACPI_PACKED_POINTERS_NOT_SUPPORTED:
    # https://github.com/acpica/acpica/issues/781#issuecomment-1718084901
    system "make", "PREFIX=#{prefix}", "OPT_CFLAGS=\"-DACPI_PACKED_POINTERS_NOT_SUPPORTED\""
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    system bin/"acpihelp", "-u"
  end
end
