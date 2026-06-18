class CreateOneTimeShares < ActiveRecord::Migration[8.0]
  def change
    create_table :one_time_shares do |t|
      t.string     :token, null: false
      t.references :aliro_config, null: true, foreign_key: { on_delete: :nullify }
      t.string     :secret_digest, null: false
      t.datetime   :expires_at, null: false
      t.datetime   :retrieved_at
      t.timestamps
    end
    add_index :one_time_shares, :token, unique: true
  end
end
