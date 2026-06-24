import asyncio # asynchronous operations 

from bleak import BleakClient, BleakScanner # needed for scanning and connecting 


from Prediction import runPrediction

MAC_ADDRESS= "99BB0507-A8C3-6A4C-2638-8584FBF4B558" # unique identifier for the module
CHAR_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb" # Characteristic UUID 

async def main():

    
    async with BleakClient(MAC_ADDRESS) as client: # creates a client connection to device
        connected =  client.is_connected 
        if not connected:
            print("Failed to connect")
            return
        buffer = b"" # b for working with bytes
        def handle_rx(_,data): # _ is a placeholder for the unused sender argument
            nonlocal buffer
            buffer +=data
            # format the data
            while b"\n" in buffer:
                line,buffer = buffer.split(b"\n",1) # get one row of data
                line_str = line.decode('utf-8').strip()
                if line_str.endswith(','):
                    line_str = line_str[:-1]  # remove trailing comma safely
                line = [float(x) for x in line_str.split(',')]
                runPrediction(line)

                

        await client.start_notify(CHAR_UUID, handle_rx) #await ensures the set up is completed 

        print("Receiving data... Press Ctrl+C to stop.")
        while True: # loop to allow for async task to continuously run
            await asyncio.sleep(1) 
        
asyncio.run(main())





