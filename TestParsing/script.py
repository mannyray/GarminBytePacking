# see https://github.com/polyvertex/fitdecode
import fitdecode

# see https://stackoverflow.com/questions/51179116/ieee-754-python
import struct
def double_to_binary_string(number):
    # Pack the number into 8 bytes using double precision format
    packed = struct.pack('>d', number)
    # Unpack it as an integer to get the 64-bit binary representation
    unpacked = struct.unpack('>Q', packed)[0]
    # Format the integer as a 64-bit binary string and return
    return f'{unpacked:064b}'
    
def binary_to_long(binary_string, start_index, end_index):
    # Slice the binary string from start_index to end_index (inclusive of start, exclusive of end)
    sliced_binary = binary_string[start_index:end_index]
    # Convert the binary string to a long integer
    long_integer = int(sliced_binary, 2)
    return long_integer

with fitdecode.FitReader('2025-02-07-16-28-55.fit') as fit:
    for frame in fit:
        if frame.frame_type == fitdecode.FIT_FRAME_DATA:
            if frame.name == "record":
                value = frame.fields[6].value
                print(value)
                
                if value is not None:
                    binary_string = double_to_binary_string(value)
                    # the lengths of data is assumed to be an agreed upon, in advance,
                    # way of encoding data so that the way data is packed in the Garmin app
                    # is the same way it will unpacked in this python script
                    ordered_lengths_of_data = [10, 13, 21, 14, 6]
                    starting_index = 0
                    for current_data_length in ordered_lengths_of_data:
                        print(binary_to_long(
                            binary_string,
                            starting_index,
                            starting_index+current_data_length
                        ))
                        starting_index = starting_index + current_data_length
