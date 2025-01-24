from pathlib import Path
import threading
from flask import Flask, render_template, jsonify, request
from werkzeug.serving import make_server

# Initialize Flask app
project_root = Path(__file__).resolve().parent.parent
templates_dir = project_root / "templates"
app = Flask(__name__, template_folder=str(templates_dir))
app.config["SELECTION_DATA"] = None

shutdown_event = threading.Event()


@app.route("/")
def index():
    start_coords = (36.2048, 138.2529)  # Centered on Japan
    zoom_level = 7
    print("Serving Map Selection UI...")
    return render_template(
        "index.html", start_coords=start_coords, zoom_level=zoom_level
    )


@app.route("/select_area", methods=["POST"])
def select_area():
    try:
        app.config["SELECTION_DATA"] = request.get_json()
        print("\nSelected Area Coordinates:")
        print(
            f"Min Latitude: {app.config['SELECTION_DATA']['min_lat']}, Min Longitude: {app.config['SELECTION_DATA']['min_lon']}"
        )
        print(
            f"Max Latitude: {app.config['SELECTION_DATA']['max_lat']}, Max Longitude: {app.config['SELECTION_DATA']['max_lon']}"
        )
        print(
            "Selected Levels of Detail (LOD):",
            ", ".join(app.config["SELECTION_DATA"]["lods"]),
        )
        print(f"Google API Key: {app.config['SELECTION_DATA']['google_api_key']}")
        print(f"Base Name: {app.config['SELECTION_DATA']['base_name']}")

        print("Setting shutdown event...\n")
        shutdown_event.set()
        return jsonify(
            {"message": "Area selection received! You can now close the browser."}
        )

    except Exception as e:
        print(f"Error in select_area: {e}")
        return jsonify({"error": str(e)}), 500


class ServerThread(threading.Thread):
    def __init__(self, app, port=5000):
        super().__init__()
        self.port = port
        try:
            self.server = make_server("0.0.0.0", self.port, app)
        except OSError as e:
            print(f"Port {self.port} is unavailable. Please check if it's in use.")
            raise e
        self.ctx = app.app_context()
        self.ctx.push()

    def run(self):
        print(f"Starting Flask server on port {self.port}...")
        try:
            self.server.serve_forever()
        except Exception as e:
            print(f"Error while running server: {e}")

    def shutdown(self):
        print("Shutting down Flask server...")
        self.server.shutdown()
        self.ctx.pop()


def run_map_selection_ui(port=5000):
    server_thread = ServerThread(app, port=port)
    server_thread.start()

    shutdown_event.wait()

    print("Shutdown event detected. Stopping server...\n")
    server_thread.shutdown()
    server_thread.join()

    return app.config["SELECTION_DATA"]
