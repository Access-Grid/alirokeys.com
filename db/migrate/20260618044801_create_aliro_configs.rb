class CreateAliroConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :aliro_configs do |t|
      t.references :domain, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string  :name, null: false
      t.string  :reader_group_id, null: false      # stored as lowercase hex
      t.string  :reader_public_key, null: false    # stored as lowercase hex
      t.string  :reader_certificate                # optional, lowercase hex
      t.boolean :is_sample, null: false, default: false
      t.timestamps
    end
    add_index :aliro_configs, [ :domain_id, :is_sample ]
  end
end
