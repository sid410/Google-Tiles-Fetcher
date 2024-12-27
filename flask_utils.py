import threading
from flask import Flask, render_template, jsonify, request
from werkzeug.serving import make_server

# Initialize Flask app
app = Flask(__name__)
app.config["SELECTION_DATA"] = None 

shutdown_event = threading.Event()


@app.route("/")
def index():
    start_coords = (36.2048, 138.2529)  # Centered on Japan
    zoom_level = 7
    print("Serving Map Selection UI...")
    return render_template("index.html", start_coords=start_coords, zoom_level=zoom_level)


@app.route("/select_area", methods=["POST"])
def select_area():
    try:
        app.config["SELECTION_DATA"] = request.get_json()
        print("\nSelected Area Coordinates:")
        print(f"Min Latitude: {app.config['SELECTION_DATA']['min_lat']}, Min Longitude: {app.config['SELECTION_DATA']['min_lon']}")
        print(f"Max Latitude: {app.config['SELECTION_DATA']['max_lat']}, Max Longitude: {app.config['SELECTION_DATA']['max_lon']}")
        print("Selected Levels of Detail (LOD):", ", ".join(app.config["SELECTION_DATA"]["lods"]))

        print("Setting shutdown event...\n")
        shutdown_event.set()
        return jsonify({"message": "Area selection received!\n You can now close the browser."})
    
    except Exception as e:
        print(f"Error in select_area: {e}")
        return jsonify({"error": str(e)}), 500


class ServerThread(threading.Thread):
    def __init__(self, app):
        super().__init__()
        self.server = make_server("0.0.0.0", 5000, app)
        self.ctx = app.app_context()
        self.ctx.push()

    def run(self):
        print("Starting Flask server...")
        self.server.serve_forever()

    def shutdown(self):
        print("Shutting down Flask server...")
        self.server.shutdown()
        self.ctx.pop()


def run_map_selection_ui():
    server_thread = ServerThread(app)
    server_thread.start()

    shutdown_event.wait()

    print("Shutdown event detected. Stopping server...\n")
    server_thread.shutdown()
    server_thread.join()

    return app.config["SELECTION_DATA"]
