import http.server
import socketserver
import sys

PORT = 8001

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Enable CORS just in case
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type')
        super().end_headers()

Handler = MyHTTPRequestHandler

print(f"Starting server on port {PORT}...")
print(f"Please open http://localhost:{PORT} in your browser.")

try:
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print("Server is running. Press Ctrl+C to stop.")
        httpd.serve_forever()
except KeyboardInterrupt:
    print("\nServer stopped.")
    sys.exit(0)
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
