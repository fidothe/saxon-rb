module Saxon
  class ItemType
    # A collection of lamba-like objects for converting XdmAtomicValues into
    # appropriate Ruby values
    module ValueToRuby
      module Convertors
        INTEGER = ->(xdm_atomic_value) {
          xdm_atomic_value.to_java.getValue
        }
      end
    end
  end
end
