from flask import Flask, request, jsonify
import paho.mqtt.client as mqtt
import logging
from dotenv import load_dotenv
import os
import time

app = Flask(__name__)

# Load environment variables
load_dotenv()

# MQTT Configuration
MQTT_BROKER_ADDRESS = os.getenv("MQTT_BROKER_ADDRESS")
MQTT_BROKER_PORT = int(os.getenv("MQTT_BROKER_PORT"))
MQTT_SUBSCRIBE_TOPIC = os.getenv("MQTT_SUBSCRIBE_TOPIC")
MQTT_PUBLISH_TOPIC = os.getenv("MQTT_PUBLISH_TOPIC")
MQTT_CLIENT_ID = os.getenv("MQTT_CLIENT_ID")
app_port_str = os.getenv("SERVER_PORT", "6000")
try:
    app_port = int(app_port_str)
except ValueError:
    print("Error: APP_PORT is not a valid integer. Using default port 6000.")
    app_port = 6000

# Initialize MQTT client
mqtt_client = mqtt.Client(MQTT_CLIENT_ID)

# Define MQTT callbacks
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT broker")
        client.subscribe(MQTT_SUBSCRIBE_TOPIC)
    else:
        print("Failed to connect to MQTT broker")

mqtt_client.on_connect = on_connect
mqtt_client.loop_start()

# Wait for MQTT broker to become available
while True:
    try:
        mqtt_client.connect(MQTT_BROKER_ADDRESS, MQTT_BROKER_PORT)
        break
    except Exception as e:
        print(f"Error connecting to MQTT broker: {e}")
        time.sleep(5)  # Wait for 5 seconds before retrying

@app.route("/ping", methods=["GET"])
def ping():
    message = "Hello from MQTT_Client"
    return jsonify(message=message), 200

@app.route("/publish", methods=["GET"])
def publish_message():
    json_message = request.args.get("jsonMessage")
    print(f"Received JSON message: {json_message}")

    # Publish the message to MQTT broker
    mqtt_client.publish(MQTT_PUBLISH_TOPIC, json_message)

    response_message = f"Message {json_message} published to MQTT broker"
    return jsonify(message=response_message), 200

if __name__ == "__main__":
    app.run(port=app_port)
