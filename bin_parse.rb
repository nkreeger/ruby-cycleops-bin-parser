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

def decode_metadata(bin_def, values)
    # I really hate this method... but let's follow the pattern for now.
    index = 0
    bin_def.fields.each do |field|
        # TODO: Actually parse out the data for these fields.
        case field.id
            when FORMAT_ID_RIDE_START
            when FORMAT_ID_RIDE_SAMPLE_RATE
            when FORMAT_ID_FIRMWARE_VERSION
            when FORMAT_ID_LAST_UPDATE
            when FORMAT_ID_ODOMETER
            when FORMAT_ID_PRIMARY_POWER_ID
            when FORMAT_ID_SECONDARY_POWER_ID
            when FORMAT_ID_CHEST_STRAP_ID
            when FORMAT_ID_CADENCE_ID
            when FORMAT_ID_SPEED_ID
            when FORMAT_ID_RESISTANCE_UNITID
        end
    end
end

def decode_ridedata(bin_def, values)
    ride_data = {}
    index = 0
    bin_def.fields.each do |field|
        value = values[index]
        ++index
        case field.id
            when FORMAT_ID_RIDE_DISTANCE
                ride_data[:distance] = value / 10000.0
            when FORMAT_ID_RIDE_TIME
                ride_data[:seconds] = value / 1000.0
            when FORMAT_ID_POWER
                ride_data[:power] = value unless value > 3000
            when FORMAT_ID_TORQUE
                ride_data[:torque] = value
            when FORMAT_ID_SPEED
                kph = value * 3.6 / 100.0
                kph = 0 if kph > 145
                ride_data[:speed] = kph
            when FORMAT_ID_CADENCE
                ride_data[:cadence] = value unless value > 255
            when FORMAT_ID_HEART_RATE
                ride_data[:heart_rate] = value unless value > 255
            when FORMAT_ID_GRADE
                value = value - 256 * 256 if value > 37768
                ride_data[:grade] = value / 100.0
            when FORMAT_ID_ALTITUDE
                # TODO
            when FORMAT_ID_ALTITUDE_OLD
                # TODO
        end
    end
    #p ride_data
end

def read_date(file)
    data = file.readbyte() +
           file.readbyte() +
           file.readbyte() +
           file.readbyte() +
           file.readbyte() +
           file.readbyte() +
           file.readbyte()
    data
end

def read_double_byte(file)
    b1 = file.readbyte() * 256
    b2 = file.readbyte()
    b1 + b2
end

def read_four_byte(file)
    b1 = file.readbyte() * 256 * 256 * 256
    b2 = file.readbyte() * 256 * 256
    b3 = file.readbyte() * 256
    b4 = file.readbyte()
    b1 + b2 + b3 + b4
end

def read_7_bytes(file)
    # Hack for now
    read_date(file)
end

def read_record(file, format_defs)
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
        end

        # TODO: Use the checksum
        checksum = file.readbyte() + file.readbyte()
        return if checksum == -1

        format_defs[format_id] = bin_def

    else  # Rest of workout data
        format_id = record_type
        cur_def = format_defs[format_id];

        ride_data = {}
        cur_def.fields.each do |field|
            value = 0        
            case field.size
                when 1
                    value = file.readbyte()
                when 2
                    value = read_double_byte(file)
                when 4
                    value = read_four_byte(file)
                when 7
                    value = read_date(file)
            end

            case field.id
                when FORMAT_ID_RIDE_DISTANCE
                    ride_data[:distance] = value / 10000.0
                when FORMAT_ID_RIDE_TIME
                    ride_data[:seconds] = value / 1000.0
                when FORMAT_ID_POWER
                    ride_data[:power] = value unless value > 3000
                when FORMAT_ID_TORQUE
                    ride_data[:torque] = value
                when FORMAT_ID_SPEED
                    kph = value * 3.6 / 100.0
                    kph = 0 if kph > 145
                    ride_data[:speed] = kph
                when FORMAT_ID_CADENCE
                    ride_data[:cadence] = value unless value > 255
                when FORMAT_ID_HEART_RATE
                    ride_data[:heart_rate] = value unless value > 254
                when FORMAT_ID_GRADE
                    value = value - 256 * 256 if value > 37768
                    ride_data[:grade] = value / 100.0
                when FORMAT_ID_ALTITUDE
                    # TODO
                when FORMAT_ID_ALTITUDE_OLD
                    # TODO
            end
        end
        p ride_data

        # TODO: Use the checksum
        checksum = file.readbyte() + file.readbyte()
        return if checksum == -1

        # Now convert the raw data
#        case format_id
#            when RECORD_TYPE_META
#                decode_metadata(cur_def, values)
#            when RECORD_TYPE_RIDE_DATA
#                decode_ridedata(cur_def, values)
#            when RECORD_TYPE_RAW_DATA
#                p "Unused data...?"
#            when RECORD_TYPE_SPARSE_DATA
#                p "record type sparse"
#            when RECORD_TYPE_INTERVAL_DATA
#                p "record type interval"
#            when RECORD_TYPE_DATA_ERROR
#                p "record type data error"
#            when RECORD_TYPE_HISTORY
#                p "record type history"
        #end
    end
end

def parse_ride_file(file)
    data_size = File.size(file)
    bytes_read = 0

    format_defs = {}

    while !file.eof
        read_record(file, format_defs)
    end

end

bin_file = open('20121129_193201.bin', 'rb') { |f| parse_ride_file(f) }
