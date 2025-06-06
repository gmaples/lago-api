# frozen_string_literal: true

class ValidateBillingEntitiesTaxesOrganizationsForeignKey < ActiveRecord::Migration[7.2]
  def change
    validate_foreign_key :billing_entities_taxes, :organizations
  end
end
