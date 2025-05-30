# frozen_string_literal: true

class SubscriptionsQuery < BaseQuery
  Result = BaseResult[:subscriptions]
  Filters = BaseFilters[:external_customer_id, :plan_code, :status]

  def call
    subscriptions = paginate(organization.subscriptions)
    subscriptions = subscriptions.where(status: filtered_statuses)
    subscriptions = apply_consistent_ordering(
      subscriptions,
      default_order: <<~SQL.squish
        subscriptions.started_at ASC NULLS LAST,
        subscriptions.created_at ASC
      SQL
    )

    subscriptions = with_external_customer(subscriptions) if filters.external_customer_id
    subscriptions = with_plan_code(subscriptions) if filters.plan_code

    result.subscriptions = subscriptions
    result
  end

  def with_external_customer(scope)
    scope.joins(:customer).where(customers: {external_id: filters.external_customer_id})
  end

  def with_plan_code(scope)
    scope.joins(:plan).where(plans: {code: filters.plan_code})
  end

  def filtered_statuses
    return [:active] unless valid_status?

    filters.status
  end

  def valid_status?
    filters.status.present? && filters.status.all? { |s| Subscription.statuses.key?(s) }
  end
end
