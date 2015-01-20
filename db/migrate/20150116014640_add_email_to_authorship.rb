class AddEmailToAuthorship < ActiveRecord::Migration
  def change
    add_column  :authorships, :email, :string
  end
end
