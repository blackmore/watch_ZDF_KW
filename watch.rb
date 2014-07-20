#encoding: UTF-8
root = File.expand_path('../', __FILE__)
require 'fileutils'
require "#{root}/config/enviroment"
require "#{root}/to_dfxp"



class Watch
  attr_accessor :file

  def initialize(file)
    reg_ad_block = /(\d+)\n(\d\d:\d\d:\d\d:\d\d).+\n(.+)/
    reg_win_ends = /\r\n/
    reg_rem_note = /\n\(.+?\)/
    file_name = File.basename(file, ".txt")
  
  
    begin
      text = File.read(file, :encoding => 'utf-8').encode!(Encoding::UTF_8)
      text.gsub!(reg_win_ends,"\n") # remove windows endings
      text.gsub!(/\(.+?\)/, "")  # remove comments in ()
      text.gsub!(/\n^\t/, " ")  # remove tabs at begings of lines 
      text.gsub!(/(\n[A-Z|a-z]+\s*[A-Z|a-z]*)\t(.+)/, "\\1\n\\2<<D\n") # find dialogs
      text.gsub!(/\nEhlers/, "\nDAVID") 
      text.gsub!(/\nGruber/, "\nTONY")
      text.gsub!(/\nBerg/, "\nLENA")
      
      #puts text.force_encoding("UTF-8")
      File.open("#{SOURCE_PATH}/#{file_name}_2URL.txt", 'w'){|file| file.write(text)}
      FileUtils.mv("#{SOURCE_PATH}/#{file_name}.txt", "#{PROCESSED_PATH}/#{file_name}.txt")
      
      # if blocks
      #   File.open("#{SOURCE_PATH}/#{file_name}_2URL.txt", 'w') do |file| 
      #     blocks.each do |block|
      #       file.write("#{block[0]} - #{block[2].slice(0, 15)}...\t#{block[1]}\n")
      #     end
      #   end
      #   FileUtils.mv("#{SOURCE_PATH}/#{file_name}.txt", "#{PROCESSED_PATH}/#{file_name}.txt")
      # end
    
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
  next if /2URL/.match(file)

  if File.file?(file)
    dir, base = File.split(file)
    Watch.new(file)
  end
end



