#encoding: UTF-8
root = File.expand_path('../', __FILE__)
require 'fileutils'
require "#{root}/config/enviroment"



class Watch
  attr_accessor :file

  def initialize(file)
    reg_ad_block = /(\d+)\n(\d\d:\d\d:\d\d:\d\d).+\n(.+)/
    reg_win_ends = /\r\n/
    reg_rem_note = /\n\(.+?\)/
    file_name = File.basename(file, ".txt")
  
  
    begin
      text = File.read(file, :encoding => 'iso-8859-1').encode!(Encoding::UTF_8)
      text.gsub!(reg_win_ends,"\n")
      text.gsub!(reg_rem_note, "")
      
      blocks = text.scan(reg_ad_block)
      
      if blocks
        File.open("#{SOURCE_PATH}/#{file_name}_midi.txt", 'w') do |file| 
          blocks.each do |block|
            file.write("#{block[0]} - #{block[2].slice(0, 15)}...\t#{block[1]}\n")
          end
        end
        FileUtils.mv("#{SOURCE_PATH}/#{file_name}.txt", "#{PROCESSED_PATH}/#{file_name}.txt")
      end
    
    rescue => err
      puts "Exception: #{err}"
      err
    end
  end
  
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# 
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Dir.chdir(SOURCE_PATH)

files = Dir['**'].collect

files.each do |file|
  next if /_midi/.match(file)

  if File.file?(file)
    dir, base = File.split(file)
    Watch.new(file)
  end
end



