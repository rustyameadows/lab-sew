class DesignSession < ApplicationRecord
  DEFAULT_PARAMS = {
    units: "in"
  }.freeze

  belongs_to :assembly_definition, optional: true

  before_validation :ensure_uuid, on: :create
  before_validation :ensure_params_snapshot, on: :create

  validates :uuid, presence: true, uniqueness: true
  validates :product_type, presence: true
  validates :params_snapshot, presence: true

  def self.default_params
    JSON.parse(DEFAULT_PARAMS.to_json)
  end

  def to_param
    uuid
  end

  private

  def ensure_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def ensure_params_snapshot
    self.params_snapshot = self.class.default_params if params_snapshot.blank?
  end

end
