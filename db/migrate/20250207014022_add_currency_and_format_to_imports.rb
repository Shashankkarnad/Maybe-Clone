class AddCurrencyAndFormatToImports < ActiveRecord::Migration[7.2]
  def change
    add_column :imports, :currency, :string
    add_column :imports, :number_format, :string
  end
end
