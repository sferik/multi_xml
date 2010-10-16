class Object #:nodoc:
  # @return <TrueClass, FalseClass>
  #
  # @example [].blank?         #=>  true
  # @example [1].blank?        #=>  false
  # @example [nil].blank?      #=>  false
  # 
  # Returns true if the object is nil or empty (if applicable)
  def blank?
    nil? || (respond_to?(:empty?) && empty?)
  end
end

class Numeric #:nodoc:
  # @return <TrueClass, FalseClass>
  # 
  # Numerics can't be blank
  def blank?
    false
  end
end

class NilClass #:nodoc:
  # @return <TrueClass, FalseClass>
  # 
  # Nils are always blank
  def blank?
    true
  end
end

class TrueClass #:nodoc:
  # @return <TrueClass, FalseClass>
  # 
  # True is not blank.  
  def blank?
    false
  end
end

class FalseClass #:nodoc:
  # False is always blank.
  def blank?
    true
  end
end

class String #:nodoc:
  # @example "".blank?         #=>  true
  # @example "     ".blank?    #=>  true
  # @example " hey ho ".blank? #=>  false
  # 
  # @return <TrueClass, FalseClass>
  # 
  # Strips out whitespace then tests if the string is empty.
  def blank?
    strip.empty?
  end
end
