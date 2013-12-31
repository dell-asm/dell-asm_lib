require 'yaml'
require 'i18n'

begin
  $MODULE_NAME = 'asm_lib'
  module_path = Puppet::Module.find($MODULE_NAME, Puppet[:environment].to_s)
  $i18n_path = File.join module_path.path, 'lib/i18n/'
  require "#{$i18n_path}/AsmLocalizedMessage"
end

class AsmException < Exception
  def initialize(msgcode, callermodule, e=nil, args=nil)
    @msgcode = msgcode
    @callermodule = callermodule
    @e= e
    @args = args
    super(e)
  end

  def e
    @e
  end

  def args
    @args
  end

  def message
    localizedmessage = self.localized_message
    msg = "\nDisplay Message - #{localizedmessage.display_message}" + "\nResponse Action - #{localizedmessage.response_action}" + "\nDetailed Description - #{localizedmessage.detailed_description}"
  end

  def localized_message
    localize_message
  end

  def log_message
    localizedmessage = self.localized_message

    Puppet.err "Display Message - #{localizedmessage.display_message}"
    Puppet.err "Response Action - #{localizedmessage.response_action}"
    Puppet.err "Detailed Description - #{localizedmessage.detailed_description}"

    if(self.e != nil)
      Puppet.err "Origin exception - #{self.e.message}"
    end
  end

  private

  def localize_message
    $DEFAULT_LOCALE = "en"
    display_message_key = "#{@msgcode}"
    response_action_key = "#{@msgcode}.ResponseAction"
    detailed_description_key = "#{@msgcode}.DetailedDescription"

    begin
      locale = (I18n.locale).to_s
    rescue Exception => e
      locale = $DEFAULT_LOCALE
    end

    if(locale == nil or locale.strip.length == 0)
      locale = $DEFAULT_LOCALE
    end

    data = read_yml_file(locale)

    if(data != nil)
      if(process_display_message(data[display_message_key]) != nil)
        display_message = process_display_message(data[display_message_key])
      else
        display_message = display_message_key
      end

      if(data[response_action_key] != nil)
        response_action = data[response_action_key]
      else
        response_action = response_action_key
      end

      if(data[detailed_description_key] != nil)
        detailed_description = data[detailed_description_key]
      else
        detailed_description = detailed_description_key
      end
    else
      display_message = display_message_key
      response_action = response_action_key
      detailed_description = detailed_description_key
    end

    asm_localized_message = AsmLocalizedMessage.new
    asm_localized_message.display_message=(display_message)
    asm_localized_message.response_action=(response_action)
    asm_localized_message.detailed_description=(detailed_description)
    asm_localized_message
  end

  def read_yml_file(locale)
    begin
      locale.downcase!()
      data = YAML.load_file "#{$i18n_path}resources/#{@callermodule}_#{locale}.yml"
    rescue Exception => e
      data = nil
    end
    return data
  end

  def process_display_message(display_message)
    ctr = 0
    if(args != nil)
      for arg in (args) do
        ctr = ctr + 1
        begin
          display_message["<#{ctr}>"] = arg
        rescue Exception => e
          #ignore and continue if arg passed to message not matched.
        end
      end
    end
    display_message
  end

end