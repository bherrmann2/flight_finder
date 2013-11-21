require 'yaml'
class NagiosPlugin

  attr_reader :exit_msg, :exit_code

  def initialize(args = nil)
    @exit_code = 1 #Unknown
    @exit_msg = "Unknown"

    return unless args

    @options = Hash.new
    last_switch = nil
    args.each do |a|
      switch = get_switch(a)
      if (switch == nil)
        @options[last_switch] = a unless (last_switch == nil)
      else
        @options[switch] = true
        last_switch = switch
      end
    end
    #puts ">>>OPTIONS:" + YAML::dump(@options)
  end

  def get_switch(s) 
    if (s =~ /^\-(\S+)/)
      return $1
    else
      return nil
    end
  end
  #
  # This method should be overritten to do the work
  #
  def start
    exit
  end
  def option(switch)
    return nil unless @options
    return @options[switch]
  end
  def error(msg = "Unknown Error")
    @exit_msg = "-ERROR-" + msg
    @exit_code = 2 
  end
  def warning(msg = "Unknown Warning")
    @exit_msg = "-WARNING-" + msg
    @exit_code = 1 
  end
  def success(msg = "OK.")
    @exit_msg = msg
    @exit_code = 0 
  end
  def exit
    puts @exit_msg
    Kernel::exit(@exit_code)
  end
end
