# -------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for
# license information.
# --------------------------------------------------------------------------

import os
import asyncio
import json
import time
import argparse
from azure.iot.device.aio import IoTHubDeviceClient


def generate_telemetry_data():
    """Generate sample telemetry data with some variation"""
    import random
    
    # Base coordinates (Moscow area)
    base_lat = 55.7558
    base_lon = 37.6176
    
    # Add some random variation to simulate movement
    lat_variation = random.uniform(-0.01, 0.01)
    lon_variation = random.uniform(-0.01, 0.01)
    noise_variation = random.uniform(-5, 5)
    
    # Random event types
    event_types = ["noise", "siren", "drone"]
    random_event_type = random.choice(event_types)
    
    return {
        "Lat": round(base_lat + lat_variation, 6),
        "Lon": round(base_lon + lon_variation, 6),
        "noise_db": round(45.2 + noise_variation, 1),
        "event_type": random_event_type,  # Randomly selected from noise, siren, drone
        "timestamp": int(time.time())
    }

async def send_telemetry_periodically(device_client, duration_minutes):
    """Send telemetry data every minute for the specified duration"""
    print(f"Starting telemetry transmission for {duration_minutes} minutes...")
    print("Sending data every 5 seconds...")
    
    start_time = time.time()
    end_time = start_time + (duration_minutes * 60)
    message_count = 0
    
    try:
        while time.time() < end_time:
            # Generate new telemetry data
            telemetry_data = generate_telemetry_data()
            message_count += 1
            
            # Convert to JSON string
            message = json.dumps(telemetry_data)
            
            # Send the message
            await device_client.send_message(message)
            print(f"[{message_count}] Telemetry sent: {telemetry_data}")
            
            # Wait for 5 seconds (0.5 minute) before next transmission
            if time.time() < end_time:  # Only wait if we haven't reached the end time
                print("Waiting 5 seconds for next transmission...")
                await asyncio.sleep(5)
                
    except KeyboardInterrupt:
        print("\nTransmission interrupted by user")
    except Exception as e:
        print(f"Error during transmission: {e}")
    
    print(f"\nTransmission completed. Total messages sent: {message_count}")

async def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Send IoT telemetry data periodically')
    parser.add_argument('--duration', type=int, default=5, 
                       help='Duration in minutes to send telemetry (default: 5)')
    args = parser.parse_args()
    
    # Fetch the connection string from an environment variable
    conn_str = os.getenv("IOTHUB_DEVICE_CONNECTION_STRING", "#### ADD CONNECTION STRING HERE ####")
    
    if conn_str == "#### ADD CONNECTION STRING HERE ####":
        print("ERROR: Please set the IOTHUB_DEVICE_CONNECTION_STRING environment variable")
        print("or update the connection string in the script")
        return

    # Create instance of the device client using the connection string
    device_client = IoTHubDeviceClient.create_from_connection_string(conn_str)

    try:
        # Connect the device client
        print("Connecting to IoT Hub...")
        await device_client.connect()
        print("Connected successfully!")

        # Send telemetry data periodically
        await send_telemetry_periodically(device_client, args.duration)

    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Finally, shut down the client
        print("Disconnecting from IoT Hub...")
        await device_client.shutdown()
        print("Disconnected.")


if __name__ == "__main__":
    asyncio.run(main())