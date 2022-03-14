class CreateProviderInfos < ActiveRecord::Migration[7.0]
  def change
    create_table :provider_infos do |t|
      t.string :number
      t.string :display_name
      t.string :display_address
      t.string :display_taxonomy
      t.timestamp :accessed_at

      t.timestamps
    end
  end
end
