class Domain < ApplicationRecord
  NAME_FORMAT = /\A[a-z0-9][a-z0-9.\-]*\.[a-z]{2,}\z/i

  has_many :aliro_configs, dependent: :destroy

  before_validation { self.name = name.to_s.strip.downcase.presence }

  validates :name, presence: true, uniqueness: true, format: { with: NAME_FORMAT }

  def sample_configs
    aliro_configs.where(is_sample: true).order(:name)
  end

  def to_param = name
end
