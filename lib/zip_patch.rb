module Zip
  class ZipCentralDirectory
    # do not do consistency check
    def read_e_o_c_d_with_abandon(io)
      begin
        read_e_o_c_d_without_abandon(io)
      rescue ZipError
        # silence error
      end
    end
    alias_method_chain :read_e_o_c_d, :abandon
  end
end
