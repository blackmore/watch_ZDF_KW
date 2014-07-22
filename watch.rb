#encoding: UTF-8
root = File.expand_path('../', __FILE__)
require 'fileutils'
# require "#{root}/dfxp_builder"
require "#{root}/config/enviroment"
require "#{root}/dfxp_builder"





class Watch < LenaParser
  attr_accessor :file

  def initialize(file)
    reg_ad_block = /(\d+)\n(\d\d:\d\d:\d\d:\d\d).+\n(.+)/
    reg_win_ends = /\r\n/
    reg_rem_note = /\n\(.+?\)/
    file_name = File.basename(file, ".txt")
  
  
    begin
      text = File.read(file, :encoding => 'utf-8').encode!(Encoding::UTF_8)
      
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # Process file with regex 
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      text.gsub!(reg_win_ends,"\n") # remove windows endings
      text.gsub!(/\(.+?\)/, "")  # remove comments in ()
      text.gsub!(/\n^\t/, " ")  # remove tabs at begings of lines 
      text.gsub!(/(\n[A-Z|a-z]+\s*[A-Z|a-z]*)\t(.+)/, "\\1\n\\2<<D\n") # find dialogs
      text.gsub!(/\nEhlers/, "\nDAVID") 
      text.gsub!(/\nGruber/, "\nTONY")
      text.gsub!(/\nBerg/, "\nLENA")
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # Build and write the xml file
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      build_DFXL = lambda do |subFile|
        b = Builder::XmlMarkup.new(:indent => 2)
        xmeml = b.instruct!(:xml, :encoding => "UTF-8")
        b.comment! "file created by nigel.blackmore@titelbild.de"
        b.tt(:xmlns => "http://www.w3.org/2006/10/ttaf1",  'xmlns:tts' => "http://www.w3.org/2006/10/ttaf1#styling") do
          b.head do
            b.styling do
              b.style("xml:id"=>"default.left", "tts:fontFamily"=>"Arial", "tts:fontSize"=>"10px", "tts:textAlign"=>"left", "tts:fontStyle"=>"normal", "tts:fontWeight"=>"normal", "tts:backgroundColor"=>"transparent", "tts:color"=>"#FFFFFF")
              b.style("xml:id"=>"default.center", :style =>"default.left",  "tts:textAlign"=>"center")
              b.style("xml:id" =>"default.right", :style =>"default.left", "tts:textAlign" =>"right")
            end
          end
          b.body do
            b.div do
              subFile.dialogs.each do |dialog|
                intime = subFile.tc
                outtime = subFile.tc + dialog.duration.to_f
                if dialog.speaker == SPEAKER_1
                  b.p(:begin =>"#{sprintf("%.2f", intime)}s", :end => "#{sprintf("%.2f", outtime)}", :dur => "#{sprintf("%.2f", dialog.duration)}s", :style => "default.center", "tts:direction" => "ltr") do
                    b.span(dialog.text, 'tts:color'=>"#FFFF00")
                  end
                elsif dialog.speaker == SPEAKER_2
                  b.p(:begin =>"#{sprintf("%.2f", intime)}s", :end => "#{sprintf("%.2f", outtime)}", :dur => "#{sprintf("%.2f", dialog.duration)}s", :style => "default.center", "tts:direction" => "ltr") do
                    b.span(dialog.text, 'tts:color'=>"#00FFFF")
                  end
                elsif dialog.speaker == SPEAKER_3
                  b.p(:begin =>"#{sprintf("%.2f", intime)}s", :end => "#{sprintf("%.2f", outtime)}", :dur => "#{sprintf("%.2f", dialog.duration)}s", :style => "default.center", "tts:direction" => "ltr") do
                    b.span(dialog.text, 'tts:color'=>"#00FF00")
                  end
                elsif dialog.speaker == SPEAKER_4
                  b.p(:begin =>"#{sprintf("%.2f", intime)}s", :end => "#{sprintf("%.2f", outtime)}", :dur => "#{sprintf("%.2f", dialog.duration)}s", :style => "default.center", "tts:direction" => "ltr") do
                    b.span(dialog.text, 'tts:color'=>"#FF00FF")
                  end
                else
                  b.p(dialog.text, :begin =>"#{sprintf("%.2f", intime)}s", :end => "#{sprintf("%.2f", outtime)}", :dur => "#{sprintf("%.2f", dialog.duration)}s", :style => "default.center", "tts:direction" => "ltr" )
                end
               subFile.tc = outtime + 0.16
              end
            end
          end
        end
      end
      
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

      FileUtils.mv("#{SOURCE_PATH}/#{file_name}.txt", "#{PROCESSED_PATH}/#{file_name}.txt")

      @newxml = File.new("#{TARGET_PATH}/#{file_name}.dfxp", 'w')
      @newxml.puts build_DFXL.call(LenaParser.new(text, file_name))
      @newxml.close
    
    rescue => err
      puts "Exception: #{err}"
      err
    end
  end
  
end

Dir.chdir(SOURCE_PATH)

files = Dir['**'].collect

files.each do |file|
  next if /2URL|.dfxp/.match(file)

  if File.file?(file)
    dir, base = File.split(file)
    Watch.new(file)
  end
end
