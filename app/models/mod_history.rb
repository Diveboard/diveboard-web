class ModHistory < ActiveRecord::Base
  validates :obj_id, :presence => true ## this is the ID
  validates :table, :presence => true ## this is the type of object
  validates :operation, :presence => true ## this is what happened to him : (delete or update)
  ##constants defined in constant.rb


  def operation_name
    return "MOD_UPDATE" if self.operation == MOD_UPDATE
    return "MOD_DELETE" if self.operation == MOD_DELETE
    return "MOD_CREATE" if self.operation == MOD_CREATE
    return "MOD_MERGE" if self.operation == MOD_MERGE
    return "MOD_PRIVATE_MERGE" if self.operation == MOD_PRIVATE_MERGE
    return "MOD_CHAIN_UPDATE" if self.operation == MOD_CHAIN_UPDATE
    return "MOD_VALIDATE_MERGE" if self.operation == MOD_VALIDATE_MERGE
    raise DBArgumentError.new "Unknown operation"
  end


end
