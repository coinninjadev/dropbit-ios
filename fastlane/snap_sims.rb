#!/usr/bin/env ruby

require 'json'

compatible_devices = [
  'iPhone SE',
  'iPhone 8',
  'iPhone 8 Plus',
  'iPhone 11',
  'iPhone 11 Pro Max'
]

available_oss = [
  'iOS 13.3'
]

device_types = JSON.parse(`xcrun simctl list -j devicetypes`)['devicetypes'].select { |i| compatible_devices.include?(i['name']) }
runtimes = JSON.parse(`xcrun simctl list -j runtimes`)['runtimes'].select { |rt| available_oss.include?(rt['name']) }.uniq
devices = JSON.parse(`xcrun simctl list -j devices`)

devices['devices'].each do |runtime, runtime_devices|
  ios_devices = runtime_devices.select { |dev| dev['name'].include?('iPhone') }
  ios_devices.each do |device|
    puts "Removing device #{device['name']} (#{device['udid']})"
    command = "xcrun simctl delete #{device['udid']}"
    _ = `#{command}`
  end
end

device_types.each do |device_type|
  runtimes.select{|runtime| runtime['isAvailable'] == true}.each do |runtime|
    puts "Creating #{device_type['name']} with #{runtime['name']}"
    command = "xcrun simctl create '#{device_type['name']}' #{device_type['identifier']} #{runtime['identifier']}"
    _ = `#{command}`
    sleep 0.5
  end
end

# devices = JSON.parse(`xcrun simctl list -j devices`)

#watches = devices.dig('devices').keep_if { |k,_| k.start_with?('watch') }.values.last
#phones = devices.dig('devices').keep_if { |k,_| k.start_with?('iOS') }.values.last
#phones = phones.keep_if { |v| v['name'].start_with?('iPhone') }
#phones = phones.delete_if { |v| v['name'].start_with?('iPhone SE')}.sort_by { |p| p['name'] }.reverse
#
#if phones.any? && watches.any?
#  watches.each_with_index do |watch, index|
#    phone = phones[index]
#    puts "Creating device pair of #{phone['udid']} and #{watch['udid']}}"
#    `xcrun simctl pair #{watch['udid']} #{phone['udid']}`
#  end
#end
