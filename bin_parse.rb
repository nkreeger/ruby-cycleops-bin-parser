#!/usr/bin/ruby

require 'open-uri'

####################################################################################################
# BIN format constants

RECORD_TYPE_META                 = 0
RECORD_TYPE_RIDE_DATA            = 1
RECORD_TYPE_RAW_DATA             = 2
RECORD_TYPE_SPARSE_DATA          = 3
RECORD_TYPE_INTERVAL_DATA        = 4
RECORD_TYPE_DATA_ERROR           = 5
RECORD_TYPE_HISTORY              = 6
FORMAT_ID_RIDE_START             = 0
FORMAT_ID_RIDE_SAMPLE_RATE       = 1
FORMAT_ID_FIRMWARE_VERSION       = 2
FORMAT_ID_LAST_UPDATE            = 3
FORMAT_ID_ODOMETER               = 4
FORMAT_ID_PRIMARY_POWER_ID       = 5
FORMAT_ID_SECONDARY_POWER_ID     = 6
FORMAT_ID_CHEST_STRAP_ID         = 7
FORMAT_ID_CADENCE_ID             = 8
FORMAT_ID_SPEED_ID               = 9
FORMAT_ID_RESISTANCE_UNITID      = 10
FORMAT_ID_WORKOUT_ID             = 11
FORMAT_ID_USER_WEIGHT            = 12
FORMAT_ID_USER_CATEGORY          = 13
FORMAT_ID_USER_HR_ZONE_1         = 14
FORMAT_ID_USER_HR_ZONE_2         = 15
FORMAT_ID_USER_HR_ZONE_3         = 16
FORMAT_ID_USER_HR_ZONE_4         = 17
FORMAT_ID_USER_POWER_ZONE_1      = 18
FORMAT_ID_USER_POWER_ZONE_2      = 19
FORMAT_ID_USER_POWER_ZONE_3      = 20
FORMAT_ID_USER_POWER_ZONE_4      = 21
FORMAT_ID_USER_POWER_ZONE_5      = 22
FORMAT_ID_WHEEL_CIRC             = 23
FORMAT_ID_RIDE_DISTANCE          = 24
FORMAT_ID_RIDE_TIME              = 25
FORMAT_ID_POWER                  = 26
FORMAT_ID_TORQUE                 = 27
FORMAT_ID_SPEED                  = 28
FORMAT_ID_CADENCE                = 29
FORMAT_ID_HEART_RATE             = 30
FORMAT_ID_GRADE                  = 31
FORMAT_ID_ALTITUDE_OLD           = 32
FORMAT_ID_RAW_DATA               = 33
FORMAT_ID_TEMPERATURE            = 34
FORMAT_ID_INTERVAL_NUM           = 35
FORMAT_ID_DROPOUT_FLAGS          = 36
FORMAT_ID_RAW_DATA_FORMAT        = 37
FORMAT_ID_RAW_BARO_SENSOR        = 38
FORMAT_ID_ALTITUDE               = 39
FORMAT_ID_THRESHOLD_POWER        = 40

####################################################################################################
# Format helper classes

class BinField
    def initialize(id, size)
        @num = 0
        @id = id
        @size = size  # in bytes
    end

    attr_accessor :num, :id, :size
end

class BinDefinition
    def initialize(id)
        @format_id = id
        @fields = []
    end

    attr_accessor :format_id, :fields
end

####################################################################################################
# Parsing methods

def decode_metadata()
end

def decode_ridedata()
end

def read_record(file)
    sum = 0
    bytes_read = 0

    record_type = file.readbyte()
    return if record_type == -1

    if record_type == 255  # Header information
        format_id = file.readbyte()
        return if format_id == -1

        bin_def = BinDefinition.new(:id => format_id)

        nb_meta = file.readbyte() + file.readbyte()
        for i in 0...nb_meta
            field_id = file.readbyte() + file.readbyte()
            field_size = file.readbyte() + file.readbyte()
            bin_def.fields.push(BinField.new(field_id, field_size))
            p "[#{i}]field_id: #{field_id}, field_size: #{field_size}"
        end

        # TODO: Use the checksum
        checksum = file.readbyte() + file.readbyte()
        return if checksum == -1
        
        p "checksum : #{checksum}"

    else  # Rest of workout data
        format_id = record_type

        ### XXX kreegeer:
        #       Left off right here... (line ~658 of BinRideFile.cpp)
        #       The implementation already has a few BinDefinition instances
        #       setup for the raw data. Do something like that.
        bin_def = BinDefinition.new(:id => format_id)
        
    end

    puts ""
end

def parse_ride_file(file)
    data_size = File.size(file)
    bytes_read = 0

    local_format_identifiers = {}

    p "data_size: #{data_size}"
    p "bytes_read: #{bytes_read}"

    read_record(file)
    read_record(file)
    read_record(file)
    read_record(file)
    read_record(file)
    read_record(file)
    read_record(file)
    read_record(file)

end

bin_file = open('20121129_193201.bin', 'rb') { |f| parse_ride_file(f) }
