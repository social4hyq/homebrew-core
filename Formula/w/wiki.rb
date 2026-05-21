class Wiki < Formula
  desc "Fetch summaries from MediaWiki wikis, like Wikipedia"
  homepage "https://github.com/walle/wiki"
  url "https://github.com/walle/wiki/archive/refs/tags/v1.4.1.tar.gz"
  sha256 "529c6a58b3b5c5eb3faab07f2bf752155868b912e4f753e432d14040ff4f4262"
  license "MIT"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "da8cbc61f89a743306016d8b0743439f5f5a9d8a97721b1da580d06da65b7d99"
  end

  deprecate! date: "2025-09-12", because: :unmaintained
  disable! date: "2026-09-12", because: :unmaintained

  depends_on "go" => :build

  # Add a User-Agent header to requests to avoid an error
  patch :DATA

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/wiki"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wiki --version")

    assert_match "Read more: https://en.wikipedia.org/wiki/Go", shell_output("#{bin}/wiki golang")
  end
end

__END__
diff --git a/request.go b/request.go
index a365760..be8e9cb 100644
--- a/request.go
+++ b/request.go
@@ -54,7 +54,13 @@ func (r *Request) Execute(noCheckCert bool) (*Response, error) {
 		client = &http.Client{Transport: tr}
 	}
 
-	response, err := client.Get(r.String())
+	req, err := http.NewRequest("GET", r.String(), nil)
+	if err != nil {
+		return nil, err
+	}
+	req.Header.Set("User-Agent", "wiki-cli/1.4.1")
+
+	response, err := client.Do(req)
 	if err != nil {
 		return nil, err
 	}
