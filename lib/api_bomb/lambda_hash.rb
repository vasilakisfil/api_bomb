#values can respond to call making them dynamic
class ApiBomb::LambdaHash < SimpleDelegator
  def self.hasharize(hash)
    hash_call = self.new(hash)
    h = {}
    hash_call.each do |v, k|
      h[v] = hash_call[v]
      if h[v].is_a? self
        h[v] = self.hasharize(h[v])
      end
    end

    return h
  end

  def is_lambda?
    self.each do |k,v|
      if self[k].is_a? self.class
        return self[k].is_lambda?
      else
        if self.real[k].respond_to? :call
          return true
        else
          return false
        end
      end
    end
  end

  def [](key)
    value = self.__getobj__[key]
    value = value.call if value.respond_to? :call
    value =  self.class.new(value) if value.is_a? Hash

    return value
  end

  def real
    self.__getobj__
  end
end
