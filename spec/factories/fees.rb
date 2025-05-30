# frozen_string_literal: true

FactoryBot.define do
  factory :fee do
    invoice
    charge { nil }
    add_on { nil }
    fee_type { "subscription" }
    subscription
    organization { invoice&.organization || subscription&.organization || association(:organization) }
    billing_entity { invoice&.billing_entity || subscription&.customer&.billing_entity || association(:billing_entity) }

    amount_cents { 200 }
    precise_amount_cents { 200.0000000001 }
    amount_currency { "EUR" }
    taxes_amount_cents { 2 }
    taxes_precise_amount_cents { 2.0000000001 }

    invoiceable_type { "Subscription" }
    invoiceable_id { subscription.id }

    invoice_display_name { Faker::Fantasy::Tolkien.character }

    trait :succeeded do
      payment_status { :succeeded }
      succeeded_at { Time.current }
    end

    trait :failed do
      payment_status { :failed }
      failed_at { Time.current }
    end

    trait :refunded do
      payment_status { :refunded }
      refunded_at { Time.current }
    end
  end

  factory :charge_fee, parent: :fee do
    invoice
    charge factory: :standard_charge
    fee_type { "charge" }

    invoiceable_type { "Charge" }
    invoiceable_id { charge.id }

    properties do
      {
        "timestamp" => Date.parse("2022-08-01 00:03:24"),
        "from_datetime" => Date.parse("2022-08-01 00:00:00"),
        "to_datetime" => Date.parse("2022-08-31 23:59:59"),
        "charges_from_datetime" => Date.parse("2022-08-01 00:00:00"),
        "charges_to_datetime" => Date.parse("2022-08-31 23:59:59")
      }
    end

    total_aggregated_units { 0 }

    trait :with_charge_filter do
      charge_filter
    end
  end

  factory :add_on_fee, class: "Fee" do
    invoice
    applied_add_on
    fee_type { "add_on" }
    subscription { nil }

    organization { invoice&.organization || association(:organization) }
    billing_entity { invoice&.billing_entity || association(:billing_entity) }

    amount_cents { 200 }
    amount_currency { "EUR" }
    taxes_amount_cents { 2 }

    invoiceable_type { "AppliedAddOn" }
    invoiceable_id { applied_add_on.id }
  end

  factory :one_off_fee, class: "Fee" do
    invoice
    add_on
    fee_type { "add_on" }
    subscription { nil }

    organization { invoice&.organization || association(:organization) }
    billing_entity { invoice&.billing_entity || association(:billing_entity) }

    amount_cents { 200 }
    amount_currency { "EUR" }
    taxes_amount_cents { 2 }

    invoiceable_type { "AddOn" }
    invoiceable_id { add_on.id }
  end

  factory :minimum_commitment_fee, class: "Fee" do
    invoice
    fee_type { "commitment" }
    subscription

    organization { invoice&.organization || association(:organization) }
    billing_entity { invoice&.billing_entity || association(:billing_entity) }

    amount_cents { 200 }
    amount_currency { "EUR" }
    taxes_amount_cents { 2 }

    transient do
      commitment { subscription.plan.minimum_commitment.presence || create(:commitment, plan: subscription.plan) }
    end

    invoiceable_type { "Commitment" }
    invoiceable_id { commitment.id }
  end
end
