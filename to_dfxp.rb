#encoding: UTF-8
require 'rubygems'
require 'builder'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# README
# BUGS - empty subtitles created if the end of a string (after a dot for example) has /s
# BUGS - subtitles created with only a full stop. Often happens if there are morn than two
# points at then end of a string.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# CONSTANTS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
MAX_DURATION = 7
MIN_DURATION = 1.5
MAX_CHR_PER_LINE = 37
CHR_PER_SECOND = 15
START_TIME = 36000.0
SPEAKER_1 = "LENA"
SPEAKER_2 = "DAVID"
SPEAKER_3 = "TONY"
SPEAKER_4 = "RAFAEL"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PARSER
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class LenaParser
  attr_accessor :file_name, :dialogs, :tc
  def initialize(file, name)
     @dialogs = []
     @file_name = name
     @tc = START_TIME

     complete_text = file.read
     complete_text.scan(/^(.+)\r*\n(.+)<<D\r*\n/) do |speaker, text|
       clean_text(text)
       if text.length > MAX_CHR_PER_LINE*2
          split_on_sentences(speaker, text)
        else
          create_subtitle_object(speaker, text)
       end
     end
  end
  
  class Dialog
    attr_accessor :text, :speaker, :duration
    def initialize
       @text = ""
       @speaker = ""
       @duration = 0.0 # unit in seconds
    end
  end
  
  def create_subtitle_object(speaker, text)
    block = Dialog.new
    block.speaker = clean_speaker(speaker)
    block.text = text
    block.duration = calc_duration(text)
    @dialogs << block
  end
  
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # TOOLS
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Replaces some unicode chrs, apostrophes and removes extra white spaces
  
  def clean_text(string)
    if string
      string.chomp!
      string.gsub!(/\t+|\(.+?\)\s*/,'')
      string.gsub!(/‘|’|„|“/, "'")
      string.squeeze!("?|!")
      string.gsub!(/!\?|\?!/, "?")
      string.gsub!(/…|!|\.\.\./, ".") # Used the three marks to keep the count clean
      string.gsub!(/(Na)(ja)/i, '\1 \2')
      string.squeeze(" ").strip
    else
      ""
    end
  end
  
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Stripes out number from the name tag and capitalizes.
  
  def clean_speaker(string)
    if string
      string.upcase!
      speaker = /([A-Z]+)/.match(string)
      if speaker
        speaker[1]
      else
        "NO_SPEAKER"
      end
    else
      "NO_SPEAKER"
    end
  end
 
 # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 # Concerdering the max and min calculates a reading speed.
 
  def calc_duration(string)
    value = string.length.to_f*1/CHR_PER_SECOND
    number = case value
      when 0..MIN_DURATION then MIN_DURATION
      when MAX_DURATION..100 then MAX_DURATION
      else value
    end
  end
  
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Splits large text blocks on sentences, ? and ! creating an array
  # of results.
  
  def split_on_sentences(speaker, string)
    aa = []
    end_index = 0
    start_index = nil
    text_length = string.length
    while true
      if end_index < text_length
        start_index = end_index
        end_index = string.index(%r{\.|\?|!}, end_index)
        end_index ||= text_length
        aa << string[start_index...end_index.next].strip
        end_index += 1
      end
      break  unless end_index < text_length
    end
    batch_subs(speaker, aa)
  end
  
  def batch_subs(speaker, aa)
    aa.each do |text|
      create_subtitle_object(speaker, text)
    end
  end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# BUILDER
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ROUTES
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# get '/' do
#   erb :form
# end

# post '/' do
#     unless params[:file] &&
#            (tmpfile = params[:file][:tempfile]) &&
#            (name = params[:file][:filename])
#       @error = "NO FILE SELECTED"
#       return erb :form
#     end
    
#    begin
#       @newxml = Tempfile.new("_NEW#{name}")
#       @newxml.puts build_DFXL.call(LenaParser.new(tmpfile, name))
#       @newxml.close
#       send_file @newxml.path, :type => 'xml', :disposition => 'attachment', :filename => "#{name.sub(/.txt/i, "")}-#{Time.now}"
#    rescue
#       @error = "PROBLEM WITH FILE: Check that you have uploaded the correct file format"
#       return erb :form
#    end
# end