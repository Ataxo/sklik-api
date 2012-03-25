# -*- encoding : utf-8 -*-

#Settings for sklik & eTarget
XMLRPC::Config.const_set(:ENABLE_NIL_PARSER, true)
XMLRPC::Config.const_set(:ENABLE_NIL_CREATE, true)

#Hack for enabling debug mode!
class XMLRPC::Client
  def set_debug out = $stderr
    @http.set_debug_output(out);
  end
end

#Hack for force encoding to UTF-8
module XMLRPCWorkAround
  def do_rpc(request, async=false)
    data = super
    data.force_encoding("UTF-8")
    data
  end
end
