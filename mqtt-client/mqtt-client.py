from flask import Flask, request, jsonify
import paho.mqtt.client as mqtt
import logging
from dotenv import load_dotenv
import os
import time

app = Flask(__name__)

# Load environment variables
load_dotenv()

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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
    logger.error("Error: app_port is not a valid integer. Using default port 6000.")
    app_port = 6000

# Initialize MQTT client
mqtt_client = mqtt.Client(MQTT_CLIENT_ID)


# Define MQTT callbacks
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        logger.info(
            f"Connected to MQTT broker {MQTT_BROKER_ADDRESS}:{MQTT_BROKER_PORT}"
        )
        client.subscribe(MQTT_SUBSCRIBE_TOPIC)
    else:
        logger.error("Failed to connect to MQTT broker")


mqtt_client.on_connect = on_connect
mqtt_client.loop_start()

# Wait for MQTT broker to become available
while True:
    try:
        mqtt_client.connect(MQTT_BROKER_ADDRESS, MQTT_BROKER_PORT)
        break
    except Exception as e:
        logger.warning(f"Error connecting to MQTT broker: {e}")
        time.sleep(5)  # Wait for 5 seconds before retrying


@app.route("/ping", methods=["GET"])
def ping():
    message = "Hello from MQTT_Client"
    logger.info(message)
    return jsonify(message=message), 200


@app.route("/publish", methods=["GET"])
def publish_message():
    json_message = request.args.get("message")
    topic = request.args.get("topic")
    logger.info(f"Received JSON message: {json_message} with topic: {topic}")

    # Publish the message to MQTT broker
    mqtt_client.publish(topic, json_message)

    response_message = f"Message {json_message} published to MQTT broker"
    logger.info(response_message)
    return jsonify(message=response_message), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=app_port)
