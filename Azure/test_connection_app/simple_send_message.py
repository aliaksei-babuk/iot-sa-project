# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------

import os
import asyncio
import json
from azure.iot.device.aio import IoTHubDeviceClient


async def main():
    # Fetch the connection string from an environment variable
    conn_str = os.getenv("IOTHUB_DEVICE_CONNECTION_STRING", "#### ADD CONNECTION STRING HERE ####")

    # Create instance of the device client using the connection string
    device_client = IoTHubDeviceClient.create_from_connection_string(conn_str)

    # Connect the device client.
    await device_client.connect()

    # Send telemetry data with Lat, Lon, noise_db parameters
    print("Sending telemetry data...")
    
    # Sample telemetry data
    telemetry_data = {
        "Lat": 55.7558,  # Latitude (Moscow coordinates as example)
        "Lon": 37.6176,  # Longitude (Moscow coordinates as example)
        "noise_db": 45.2  # Noise level in decibels
    }
    
    # Convert to JSON string
    message = json.dumps(telemetry_data)
    
    # Send the message
    await device_client.send_message(message)
    print(f"Telemetry data successfully sent: {telemetry_data}")

    # Finally, shut down the client
    await device_client.shutdown()


if __name__ == "__main__":
    asyncio.run(main())