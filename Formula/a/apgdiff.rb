class Apgdiff < Formula
  desc "Another PostgreSQL diff tool"
  homepage "https://www.apgdiff.com/"
  url "https://github.com/fordfrog/apgdiff/archive/refs/tags/release_2.7.0.tar.gz"
  sha256 "932a7e9fef69a289f4c7bed31a9c0709ebd2816c834b65bad796bdc49ca38341"
  license "MIT"
  revision 1

  livecheck do
    url :stable
    regex(/^release[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "508e01b170e9d5f717f448b505104bf3972960f556d3e7084bfc2ba747277080"
  end

  head do
    url "https://github.com/fordfrog/apgdiff.git", branch: "develop"
    depends_on "ant" => :build
  end

  depends_on "openjdk"

  def install
    jar = "releases/apgdiff-#{version}.jar"

    if build.head?
      system "ant", "-Dnoget=1"
      jar = Dir["dist/apgdiff-*.jar"].first
    end

    libexec.install jar
    bin.write_jar_script libexec/File.basename(jar), "apgdiff"
  end

  test do
    sql_orig = testpath/"orig.sql"
    sql_new = testpath/"new.sql"

    sql_orig.write <<~SQL
      SET search_path = public, pg_catalog;
      SET default_tablespace = '';
      CREATE TABLE testtable (field1 integer);
      ALTER TABLE public.testtable OWNER TO fordfrog;
    SQL

    sql_new.write <<~SQL
      SET search_path = public, pg_catalog;
      SET default_tablespace = '';
      CREATE TABLE testtable (field1 integer,
        field2 boolean DEFAULT false NOT NULL);
      ALTER TABLE public.testtable OWNER TO fordfrog;
    SQL

    expected = <<~SQL.strip
      ALTER TABLE testtable
      \tADD COLUMN field2 boolean DEFAULT false NOT NULL;
    SQL

    assert_equal expected, shell_output("#{bin}/apgdiff #{sql_orig} #{sql_new}").strip
  end
end
