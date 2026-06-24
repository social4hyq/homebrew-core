class Resterm < Formula
  desc "Terminal client for .http/.rest files with HTTP, GraphQL, and gRPC support"
  homepage "https://github.com/unkn0wn-root/resterm"
  url "https://github.com/unkn0wn-root/resterm/archive/refs/tags/v0.44.1.tar.gz"
  sha256 "285b609c81dcf2359ddddea637a0d52bd4261442f08c2412c21d4ed74c2e1e26"
  license "Apache-2.0"
  head "https://github.com/unkn0wn-root/resterm.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ohos: "78993c03697330780e495bc0b36d770025bc6611a3457ec14b9bf4a81184d7b4"
  end

  depends_on "go" => :build

  def install
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{tap.user} -X main.date=#{time.iso8601}"
    system "go", "build", *std_go_args(ldflags:), "./cmd/resterm"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/resterm -version")

    (testpath/"openapi.yml").write <<~YAML
      openapi: 3.0.0
      info:
        title: Test API
        version: 1.0.0
        description: A simple test API
      servers:
        - url: https://api.example.com
          description: Production server
      paths:
        /ping:
          get:
            summary: Ping endpoint
            operationId: ping
            responses:
              "200":
                description: Successful response
                content:
                  application/json:
                    schema:
                      type: object
                      properties:
                        message:
                          type: string
                          example: "pong"
      components:
        schemas:
          PingResponse:
            type: object
            properties:
              message:
                type: string
    YAML

    system bin/"resterm", "--from-openapi", testpath/"openapi.yml",
                          "--http-out",     testpath/"out.http",
                          "--openapi-base-var", "apiBase",
                          "--openapi-server-index", "0"

    assert_match "GET {{apiBase}}/ping", (testpath/"out.http").read
  end
end
