class DesignSession < ApplicationRecord
  before_validation :ensure_uuid, on: :create

  validates :uuid, presence: true, uniqueness: true
  validates :product_type, presence: true
  validates :params_snapshot, presence: true

  def to_param
    uuid
  end

  private

  def ensure_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
