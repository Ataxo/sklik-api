class SklikApi

  class NotFound < Exception; end
  class InvalidArguments < Exception; end
  class InvalidData < Exception; end
  class ServiceTemporarilyUnavailable < Exception; end
  class Forbidden < Exception; end
end