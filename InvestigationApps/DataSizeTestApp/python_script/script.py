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

counters = []
timestamps = []
diff = []
#2025-02-10-14-34-31.fit - original 18 hour experiment
#2025-02-12-12-40-26.fit - 10 hour, 2nd, experiment, contains diff element
#2025-02-26-09-54-51.fit - 18 hour experiment, writing every 1050ms
# ^ max entry reached there was 63911
with fitdecode.FitReader('2025-02-12-12-40-26.fit') as fit:
    for frame in fit:
        if frame.frame_type == fitdecode.FIT_FRAME_DATA:
            if frame.name == "record":
                value = frame.fields[-1].value
                
                if value is not None:
                    binary_string = double_to_binary_string(value)
                    # the lengths of data is assumed to be an agreed upon, in advance,
                    # way of encoding data so that the way data is packed in the Garmin app
                    # is the same way it will unpacked in this python script
                    ordered_lengths_of_data = [2, 16, 26, 11]
                    starting_index = 0
                    for current_data_length in ordered_lengths_of_data:
                        processed_sub_value = binary_to_long(    binary_string,
                            starting_index,
                            starting_index+current_data_length
                        )
                        if current_data_length == 16:
                            counters.append(processed_sub_value)
                        elif current_data_length == 26:
                            timestamps.append(processed_sub_value)
                        elif current_data_length == 11:
                            diff.append(processed_sub_value)
                        starting_index = starting_index + current_data_length

"""
gives a histogram data of how long between
consecutive timestamps (that are not the skipped 2 second type)
"""
def timestamp_analyze(arr, timestamps):
    dict = {}
    for i in range(1, len(arr)):
        if arr[i] == 65535:#63911
            break
        difference_key = timestamps[i] - timestamps[i-1]
        if difference_key > 1990:
            continue
        if difference_key not in dict:
            dict[difference_key] = 1
        else:
            dict[difference_key] = dict[difference_key] + 1
    sorted_array = sorted(dict.items())
    return sorted_array

"""

"""
def is_increasing_by_one(arr, timestamps):
    discreps = []
    for i in range(1, len(arr)):
        if arr[i] == 65535:
            break
        if arr[i] - arr[i - 1] != 1:
            discreps.append([arr[i],timestamps[i]])#, arr[i] - arr[i - 1],diff[i],diff[i+1]])
    return discreps

discrep = is_increasing_by_one(counters,timestamps)
print(discrep)
print("total skipped count "+str(len(discrep)))
print("max counter "+str(counters[-1]))

print(timestamp_analyze(counters,timestamps))
